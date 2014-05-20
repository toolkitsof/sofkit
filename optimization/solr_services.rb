module OptimizationTask

  module SolrServices
    # Returns random (with some constrains) questions from solr
    def get_questions_from_solr
      # Send a request to /select

      request_params = {
        :q => "*:*",
        :fl => 'Id, AcceptedAnswerId, CreationDate',
        :defType => 'edismax',
        :sort => "random" + [*100..999].sample.to_s + " desc",
        :fq => "CreationDate:[2013-01-01T00:00:00.00Z TO NOW] AND NOT AcceptedAnswerId:\"\"",
        :rows => @config[:query_parameters][:initial_questions_count]
      }

      solr_response = @solr_stackoverflow_indexed.get 'select', :params => request_params
    
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

    # Query with mlt on question to get parsedquery (parses the important words of the question to query with grades)
    def get_query_by_mlt question
      puts "INFO: get_similar_questions_from_solr"
      # Send a request to /select
      # TODO: Make sure this params are also used in Blacklight
      request_params = {
        :q => "Id:#{question.question_id}",
        #:defType => 'edismax',
        :mlt => 'true',
        :'mlt.fl'.to_sym => 'Title, Tags, Title, Tags',
        :'mlt.minwl'.to_sym => 3,
        :'mlt.maxqt'.to_sym => 1000,
        :'mlt.mindf'.to_sym => 1,
        :'mlt.mintf'.to_sym => 1,
        :'mlt.boost' => true,
        :'mlt.qf'.to_sym => 'Title^10 Tags^5',
        :'debugQuery' => true,
        :rows => 0 # We just want the parsedquery
      }

      solr_response = @solr_stackoverflow_indexed.get 'mlt', :params => request_params

      parsed_query = solr_response['debug']['parsedquery']
    end
    
    # Returns a list of answerers by query
    def get_answerers_by_question_similarity query
      # Answerers with NumAnswered below this value will get boost, answerers with NumAnswered above this value will get negative boost
      num_answered_boost_limit = 200
    
      request_params = {
        :q => query,
        :fl => 'AnswererId',
        :defType => 'edismax',
        :boost => "recip(NumAnswered,1,1,#{num_answered_boost_limit})",
        :stopwords => true,
        :lowercaseOperators => true,
        :rows => 100
      }

      solr_response = @solr_answerer_connection.get 'select', :params => request_params
    
      return {
        'success' => true,
        'answerers' => solr_response['response']['docs'].map { |doc| doc['AnswererId'] }
      }
    end
    
    # Returns a document by id
    def get_by_id id
      request_params = {
        :q => "Id:#{id}",
        :fl => '*'
      }

      solr_response = @solr_stackoverflow_indexed.get 'select', :params => request_params
      docs = solr_response['response']['docs']
      
      if docs.count == 1
        return {
          'success' => true,
          'doc' => docs[0]
        }
      else
        return {
          'success' => false,
          'message' => "Returned #{docs.count} items"
        }
      end
    end
  end
end
