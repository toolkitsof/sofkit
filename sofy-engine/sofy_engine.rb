require_relative './services/solr_services.rb'
require_relative './services/stackoverflow_services.rb'

module SofyEngine
  include SolrServices
  include StackoverflowServices

  def initialize_engine config
    @config = config
    @mlt_request = @config['mlt_params']
    @similatiry_query = @config['similarity_query_params']
    
    # Connect to Solr
    #url = "http://146.148.24.118:8983/solr/"
    url = "http://130.211.93.220:8983/solr/"
    @solr_stackoverflow_indexed = RSolr.connect :url => url + 'collection1'
    @solr_answerer_connection = RSolr.connect :url => url + 'collection2'
    
  end
  
  def return_answerers_ids question
    begin
      original_question_id = question.question_id
      
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