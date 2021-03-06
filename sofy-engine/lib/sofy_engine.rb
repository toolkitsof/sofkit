require_relative './services/solr_services.rb'
require_relative './services/stackoverflow_services.rb'

module SofyEngine
  include SolrServices
  include StackoverflowServices

  def initialize_engine config
    @config = config
    @mlt_request = @config['mlt_params']

    @similatiry_query = @config['similarity_query_params']
    @question_similarity_query = @config['question_similarity_params']

    @body_query_params = @config['body_query_params']

    @body_query_params_answerer = @config['body_query_params_answerer']
    @body_query_params_question = @config['body_query_params_question']

    # Connect to Solr
    #url = "http://130.211.93.220:8983/solr/"
    url = "http://localhost:8983/solr/"
	  @solr_stackoverflow_indexed = RSolr.connect :url => url + 'collection1'
    @solr_answerer_connection = RSolr.connect :url => url + 'collection2'
    
  end
  
  # This is used for optimizations to play with configurations
  def update_engine_config mlt_config, body_query_answerer_config, body_query_question_config
    @mlt_request = @mlt_request.merge mlt_config
    @body_query_params_answerer = @body_query_params_answerer.merge body_query_answerer_config
    @body_query_params_question = @body_query_params_question.merge body_query_question_config
  end
  
  def return_answerers_ids question, index_question=true
    
    begin
      original_question_id = question.question_id
      
      if index_question
        index_question_to_solr question
      end
      
      # Get the query created by mlt on question
      query = get_query_by_mlt question
      
      puts "parsedquery: #{query}"
      
      # Send query
      response = get_answerers_by_question_similarity query
      
      if !response['success']
        puts response['message']
      else
        return response['answerers'], query
      end
    rescue Exception => e
      puts "EXCEPTION! ex.: #{e}"
    end
  end
end