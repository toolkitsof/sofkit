require 'ruby-stackoverflow'
require 'rsolr'
require 'debugger'

require './solr_services.rb'
require './stackoverflow_services.rb'

config = {
  :stackoverflow => {
    :paginate_query => 30
  },
  :query_parameters => {
    :similar_questions_count => 8000,
    :initial_questions_count => 200
  },
  :mlt_parameters => {
    :mlt_fl => 'Title, Tags, Title, Tags',
    :mlt_qf => 'Title^10 Tags^2 Body^1'
  }
}

puts
puts "Configuration: #{config.inspect}"
puts

module OptimizationTask
  include SolrServices
  include StackoverflowServices

  def start config
    @config = config
    
    # Direct connection
    url = "http://146.148.24.118:8983/solr/"
    @solr_stackoverflow_indexed = RSolr.connect :url => url + 'collection1'
    @solr_answerer_connection = RSolr.connect :url => url + 'collection2'
    
    #response = get_questions_from_stack_overflow
    response = get_questions_from_solr
    
    if !response['success']
      puts response['message']
    else
      questions = response['questions']
      
      puts "Received #{questions.count} questions"
      
      number_of_good_questions = 0
      number_of_bad_questions = 0
      
      # Iterate chosen questions
      counter = 1
      for question in questions
        begin
          original_question_id = question.question_id
          original_question_accepted_answer_id = question.accepted_answer_id

          puts "#{counter}. Question #{original_question_id}"
          
          # Get the query created by mlt on question
          query = get_query_by_mlt question
          
          # Send query
          response = get_answerers_by_question_similarity query
          
          if !response['success']
            puts response['message']
          else
            answerers_suggested_ids = response['answerers']
            
            response = get_by_id(original_question_accepted_answer_id)
            if !response['success']
              puts response['message']
            else
              # The original's question answer documnet
              answer_document = response['doc']
              question_answerer_id = answer_document['OwnerUserId']
              
              # Compare if the original question answerer is also one of the suggested answerers
              if answerers_suggested_ids.include? question_answerer_id
                puts "GOOD ONE!"
                number_of_good_questions = number_of_good_questions + 1
              else
                puts "BAD ; Number of answerers suggested #{answerers_suggested_ids.count}"
                
                number_of_bad_questions = number_of_bad_questions + 1
              end
            end
          end
          
          puts "STATUS: number_of_good_questions: #{number_of_good_questions} | number_of_bad_questions #{number_of_bad_questions}"
        rescue Exception => e
          #debugger
          puts "EXCEPTION! ex.: #{e}"
        end
        
        puts
        counter = counter + 1
      end
    end
  end
end

include OptimizationTask

start config
