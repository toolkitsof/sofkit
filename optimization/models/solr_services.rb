module OptimizationTask

  module SolrServices
    # Returns random (with some constrains) questions from solr
    def get_questions_from_solr
      # Send a request to /select

      request_params = {
        :q => "CreationDate:[2013-01-01T00:00:00.00Z TO NOW] AND NOT AcceptedAnswerId:\"\"",
        :fl => 'Id, AcceptedAnswerId, CreationDate',
        #:defType => 'edismax',
        #:sort => "random" + [*100..999].sample.to_s + " desc",
        :sort => "random" + "34631" + " desc",
        :fq => "Score:/./ AND NOT Score:0",
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


    def get_question_from_solr question_id
      # Send a request to /select

      request_params = {
          :q => "Id:#{question_id.to_s}",
          :fl => 'Id, AcceptedAnswerId, CreationDate'
      }

      solr_response = @solr_stackoverflow_indexed.get 'select', :params => request_params

      # Format response as a RubyStackoverflow Question object
      questions = solr_response['response']['docs'].
          map { |doc| RubyStackoverflow::Client::Question.new({
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

      request_params = @mlt_request

      request_params[:q] = "Id:#{question.question_id}"

      solr_response = @solr_stackoverflow_indexed.get 'mlt', :params => request_params

      parsed_query = solr_response['debug']['parsedquery']
    end
    
    # Returns a list of answerers by query
    def get_answerers_by_question_similarity query


      request_params = {
          :q => query,
          :fl => 'NumAnswered',
          :rows => 40
      }

      solr_response = @solr_answerer_connection.get 'select', :params => request_params

      sumAnswers = 0;
      solr_response['response']['docs'].each { |doc| sumAnswers = sumAnswers + doc['NumAnswered'] }
      avgAnswers = sumAnswers / 40
      num_answered_boost_limit = avgAnswers
      print(num_answered_boost_limit)
=begin
      request_params = {
          :q => query,
          :stats => true,
          :'stats.field'.to_sym => 'NumAnswered',
          :rows => 0
      }

      solr_response = @solr_answerer_connection.get 'select', :params => request_params

      avgAnswers = solr_response['stats']['stats_fields']['NumAnswered']['mean']
      stddev = solr_response['stats']['stats_fields']['NumAnswered']['stddev']
=end
      # Answerers with NumAnswered below this value will get boost, answerers with NumAnswered above this value will get negative boost
      #num_answered_boost_limit = avgAnswers + (8 * stddev)

      request_params = @similatiry_query
      request_params[:q] = query
      request_params[:boost] = "recip(NumAnswered,1,#{2 * num_answered_boost_limit},#{num_answered_boost_limit})"



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

    # Returns a document by id
    def check_answerer_exists id
      request_params = {
          :q => "AnswererId:#{id}",
          :fl => 'AnswererId'
      }

      solr_response = @solr_answerer_connection.get 'select', :params => request_params
      docs = solr_response['response']['docs']

      if docs.count == 1
        return {
            'success' => true,
            'doc' => docs[0]
        }
      else
        return {
            'success' => false,
            'message' => "Returned #{docs.count} users"
        }
      end
    end

  end
end
