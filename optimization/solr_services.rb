module OptimizationTask
  module SolrServices
    # Will get all answers from solr
    def get_all_answers_from_solr questions
      puts "INFO: get_all_answers_from_solr"

      # Used to gather all answers
      questions_answers = {}
      
      
      questions_dictionary = {}
      questions.each do |question|
        questions_dictionary[question.question_id] = question
      end
      
      questions_ids = questions.map { |question| question.question_id }
      questions_ids_parsed = questions_ids.join(" OR ")
      
      # Send a request to /select
      # TODO: Make sure this params are also used in Blacklight
      request_params = {
        :q => "ParentId:(#{questions_ids_parsed})",
        :defType => 'edismax',
        :fq => 'AnswerCount:""',
        :rows => 1000
      }
      
      solr_response = @solr.get 'select', :params => request_params
      
      # TODO: Complete
      questions_answers = {}
      solr_response["response"]["docs"].each do |answer|
        question_id = answer['ParentId'].to_i
        question = questions_dictionary[question_id]
        is_accepted = question.accepted_answer_id == answer['Id'].to_i
        
        questions_answers[question_id] = [] if questions_answers[question_id].nil?
        
        # Format response as a RubyStackoverflow Answer object
        questions_answers[question_id] << RubyStackoverflow::Client::Answer.new({
          :'is_accepted' => is_accepted,
          :'owner' => {
            :'user_id' => answer['OwnerUserId'].to_i
          }
        })
      end
      
      return questions_answers
    end
    
    def get_questions_from_solr
      min_votes = @config[:stackoverflow][:min_votes]
    
      # Send a request to /select
      # TODO: Make sure this params are also used in Blacklight
      request_params = {
        :q => "*:*",
        :fl => 'Id, AcceptedAnswerId',
        :defType => 'edismax',
        :fq => "+Score:#{min_votes} -AcceptedAnswerId:\"\"",
        :rows => 50
      }
      
      solr_response = @solr.get 'select', :params => request_params
    
      # Format response as a RubyStackoverflow Question object
      questions = solr_response['response']['docs'].map { |doc| RubyStackoverflow::Client::Question.new({
          :'question_id' => doc['Id'].to_i,
          :'accepted_answer_id' => doc['AcceptedAnswerId'].to_i
        })
      }
    
      return {
        'success' => true,
        'questions' => questions
      }
    end

    # Receives a question and returns similar questions from solr.
    # We can do this in 2 ways:
    # 1) Use Solr's More Like This Mechanism.
    # 2) Put the question body in solr's query.
    def get_similar_questions_from_solr question, use_more_like_this = true
      puts "INFO: get_similar_questions_from_solr"
      
      # TODO: Before using more like this, add a check if the item is in solr. If not - index it.
      
      if (use_more_like_this)
        # Send a request to /select
        # TODO: Make sure this params are also used in Blacklight
        request_params = {
          :q => "Id:#{question.question_id}",
          #:defType => 'edismax',
          :mlt => 'true',
          :'mlt.fl'.to_sym => 'Body, Title, Tags',
          :'mlt.qf'.to_sym => 'Body^2.5 Title^10 Tags^2',
          #:'mlt.qf' => 'Body_t^10 Title_t^10',
          :fq => '-AcceptedAnswerId:""',
          :'rows'.to_sym => @config[:solr][:similar_questions_count]
        }
        
        solr_response = @solr.get 'mlt', :params => request_params
        
        similar_docs_from_solr = solr_response["response"]["docs"]
        if similar_docs_from_solr.nil?
          similar_questions = []
        else
          similar_questions = similar_docs_from_solr
        end
      else
        # Send a request to /select
        # TODO: Make sure this params are also used in Blacklight
        request_params = {
          :q => question.body,
          :defType => 'edismax',
          :qf => 'Body^10 Title^10',
          # :qf => 'Body_t^10 Title_t^10',
          :rows => 30
        }
        
        solr_response = @solr.get 'select', :params => request_params

        # Manipulate results
        similar_questions = solr_response["response"]["docs"]
      end
      
      similar_questions = similar_questions.map { |doc| RubyStackoverflow::Client::Question.new({
          :'question_id' => doc['Id'].to_i,
          :'accepted_answer_id' => doc['AcceptedAnswerId'].to_i
        })
      }  
    end
  end
end