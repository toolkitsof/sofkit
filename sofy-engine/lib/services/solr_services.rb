require 'date'

module SofyEngine

  module SolrServices
    # Returns random (with some constrains) questions from solr
    def get_questions_from_solr
      # Send a request to /select

      request_params = {
        :q => "LastActivityDate:[2013-01-01T00:00:00.00Z TO NOW] AND NOT AcceptedAnswerId:\"\"",
        :fl => 'Id, AcceptedAnswerId, CreationDate',
        #:defType => 'edismax',
        #:sort => "random" + [*100..999].sample.to_s + " desc",
        :sort => "random" + "3a4631" + " desc",
        #:fq => "NOT AnswerCount:0 AND NOT AnswerCount:1 AND NOT AnswerCount:2",
        #:fq => "AnswerCount:[2 TO *]",
        :rows => @config['query_parameters']['initial_questions_count']
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

    # Returns random (with some constrains) answerers_ids from solr
    def get_answerers_ids_from_solr
      # Send a request to /select

      request_params = {
        :q => "LastActivityDate:[2013-01-01T00:00:00.00Z TO NOW] AND NOT AcceptedAnswerId:\"\"",
        :fl => 'Id, AcceptedAnswerId, CreationDate',
        #:defType => 'edismax',
        #:sort => "random" + [*100..999].sample.to_s + " desc",
        :sort => "random" + "7f4471" + " desc",
        #:fq => "NOT AnswerCount:0 AND NOT AnswerCount:1 AND NOT AnswerCount:2",
        #:fq => "AnswerCount:[2 TO *]",
        :rows => @config['query_parameters']['initial_questions_count']
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

    def index_question_to_solr question
      #2009-12-25T11:29:20+00:00 bad
      #2010-09-24T10:47:36.927Z good
      if question.instance_variables.include? :@accepted_answer_id
        accepted_answer_id = question.accepted_answer_id
      else
        accepted_answer_id = " "
      end
      
      # Split question.tags by indexer rules
      question_tags = question.tags.join('><')
      question_tags = '<' + question_tags + '>'
      
      # Index to solr
      @solr_stackoverflow_indexed.add :Id => question.question_id, :ParentId=> "".to_s, :PostTypeId=> "2", :AcceptedAnswerId => accepted_answer_id, :CreationDate=> DateTime.parse(question.creation_date).to_time.utc.iso8601, :Score=> question.score, :Body=> question.body, :OwnerUserId=> question.owner[:user_id], :LastActivityDate=> DateTime.parse(question.last_activity_date).to_time.utc.iso8601, :Title=> question.title, :Tags => question_tags, :AnswerCount=> question.answer_count
      @solr_stackoverflow_indexed.commit
    end

    # Query with mlt on question to get parsedquery (parses the important words of the question to query with grades)
    def get_body_mlt_for_question question
      mintf = @body_query_params_question['mintf']
      maxtf = @body_query_params_question['maxtf']
      mindf = @body_query_params_question['mindf']
      maxdf = @body_query_params_question['maxdf']
      bodyboost = @body_query_params_question['bodyboost']

      request_params = @body_query_params
      request_params[:q] = "Id:#{question.question_id}"
      solr_response = @solr_stackoverflow_indexed.get 'tvrh', :params => request_params

      body_q = ""
      b = solr_response['termVectors'][3][3]
      for i in 0..b.length
        if i%2 == 1
          if b[i][1] >= mintf and b[i][1] <= maxtf and b[i][3] >= mindf and b[i][3] <= maxdf
            body_q = body_q + "Body:" + b[i-1] + "^#{bodyboost} "
          end
        end
      end

      body_q
    end

    def get_body_mlt_for_answerer answerer
      mintf = @body_query_params_answerer['mintf']
      maxtf = @body_query_params_answerer['maxtf']
      mindf = @body_query_params_answerer['mindf']
      maxdf = @body_query_params_answerer['maxdf']
      bodyboost = @body_query_params_answerer['bodyboost']

      request_params = @body_query_params
      request_params[:q] = "AnswererId:#{answerer}"
      solr_response = @solr_answerer_connection.get 'tvrh', :params => request_params

      body_q = ""
      b = solr_response['termVectors'][3][3]
      for i in 0..b.length
        if i%2 == 1
            if b[i][1] >= mintf and b[i][1] <= maxtf and b[i][3] >= mindf and b[i][3] <= maxdf
              body_q = body_q + "Body:" + b[i-1] + "^#{bodyboost} "
            end
        end
      end

      body_q
    end

    # Query with mlt on question to get parsedquery (parses the important words of the question to query with grades)
    def get_query_by_mlt question
      puts "INFO: get_similar_questions_from_solr"
      
      request_params = @mlt_request

      request_params[:q] = "Id:#{question.question_id}"

      title_boost = @mlt_request['titleBoost']
      tags_boost = @mlt_request['tagsBoost']
      request_params['mlt.qf'.to_sym] = "Title^#{title_boost} Tags^#{tags_boost}"
      
      # Choose this when there is body in query
      #body_boost = @mlt_request['bodyBoost']
      #request_params['mlt.qf'.to_sym] = "Title^#{title_boost} Tags^#{tags_boost} Body^#{body_boost}"
      
      solr_response = @solr_stackoverflow_indexed.get 'mlt', :params => request_params

      #TODO: merge here results from custom mlt

      body_question_query = get_body_mlt_for_question question
      puts body_question_query
      parsed_query = body_question_query + solr_response['debug']['parsedquery']
    end

    # Query with mlt on question to get parsedquery (parses the important words of the question to query with grades)
    def get_questionids_by_mlt answerer
      puts "INFO: get_similar_questions_from_solr"

      request_params = @mlt_request

      request_params[:q] = "AnswererId:#{answerer}"

      solr_response = @solr_answerer_connection.get 'mlt', :params => request_params

      parsed_query = solr_response['debug']['parsedquery']

      body_query = get_body_mlt_for_answerer answerer
      parsed_query = body_query + parsed_query
      
      request_params = @question_similarity_query
      request_params[:q] = parsed_query

      suggested_questions = @solr_stackoverflow_indexed.get 'select', :params => request_params
    end

    # Fixes the query (Removes special characther : when not needed)
    def fix_query query
      newQuery = ''
      queryParts = query.split(' ')
      newQueryParts = []
      
      queryParts.each do |queryPart|
        if queryPart.count(':') > 1
          queryPart.gsub!(/(.*)(:)(.*)/, '\1\\:\3')
        end
        
        newQueryParts << queryPart
      end
      
      # Rebuild the new query
      newQuery = newQueryParts.join ' '
    end
    
    # Returns a list of answerers by query
    def get_answerers_by_question_similarity query
      query = fix_query query
      
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

      # Get the answerers ids of similar questions
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
    def get_by_parent_id id
      request_params = {
          :q => "ParentId:#{id} ",
          :fl => '*'
      }
      solr_response = @solr_stackoverflow_indexed.get 'select', :params => request_params
      answerers = solr_response['response']['docs'].map { |doc| doc['OwnerUserId'] }

      if answerers.count >= 1
        return {
            'success' => true,
            'answerers' => answerers
        }
      else
        return {
            'success' => false,
            'message' => "Returned #{answerers.count} items"
        }
      end
    end

    # Returns a document by id
    def filter_answerer_exists owners, questionID
      query = ""
      owners.map{ |x| if (x.to_s.length > 0 )
                        query += " OR " + x.to_s
                      end
      }
      query=query.sub(" OR ", "")
      query = "AnswererId:(#{query}) AND NOT AnsweredQuestionIds:#{questionID}"
      puts query
      request_params = {
          :q => "#{query}",
          :fl => 'AnswererId'
      }

      if (query.length > 0)
        solr_response = @solr_answerer_connection.get 'select', :params => request_params
        res = solr_response['response']['docs'].map { |doc| doc['AnswererId'] }
      end


      return res
    end

  end
end
