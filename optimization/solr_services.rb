module OptimizationTask

  module SolrServices
    # Receives questions
    # Returns all answers from solr
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
        :rows => 8000
      }
      
      solr_response = @solr.post('select', :params => request_params)
      
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
    
    # Returns random (with some constrains) questions from solr
    def get_questions_from_solr
      min_votes = @config[:query_parameters][:min_votes]
    
      # Send a request to /select

      request_params = {
        :q => "*:*",
        :fl => 'Id, AcceptedAnswerId, CreationDate',
        :defType => 'edismax',
        :sort => "random" + [*100..999].sample.to_s + " desc",
        :fq => " -AcceptedAnswerId:\"\"",
        :rows => 500
      }

      solr_response = @solr.get 'select', :params => request_params
    
      # Format response as a RubyStackoverflow Question object
      questions = solr_response['response']['docs'].map { |doc| RubyStackoverflow::Client::Question.new({
          :'question_id' => doc['Id'].to_i,
          :'created_date' => doc['CreationDate'].to_s,
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
          :'mlt.fl'.to_sym => @config[:query_parameters][:mlt_fl],
          :'mlt.qf'.to_sym => @config[:query_parameters][:mlt_qf],
          :'mlt.minwl'.to_sym => 3,
          :'mlt.maxqt'.to_sym => 89,
          :fq => ["CreationDate:[* TO #{question.created_date}]","-AcceptedAnswerId:\"\""],
          :rows => @config[:query_parameters][:similar_questions_count]
        }

        print request_params

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
          :qf => @config[:query_parameters][:mlt_qf],
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
