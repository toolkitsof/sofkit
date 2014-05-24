require 'ruby-stackoverflow'
require 'rsolr'
require 'debugger'

require './solr_services.rb'
require './stackoverflow_services.rb'

configs = [
{
  :query_parameters => {
    :initial_questions_count => 500
  }
}
]

module OptimizationTask
  include SolrServices
  include StackoverflowServices

  def start config
    @config = config
    
    # Direct connection
    #url = "http://146.148.24.118:8983/solr/"
    url = "http://localhost:8983/solr/"
    @solr_stackoverflow_indexed = RSolr.connect :url => url + 'collection1'
    @solr_answerer_connection = RSolr.connect :url => url + 'collection2'

    @mlt_request = {
        #:defType => 'edismax',
        :mlt => 'true',
        :stopwords => true,
        :'mlt.fl'.to_sym => 'Tags, Title',
        :'mlt.minwl'.to_sym => 3,
        :'mlt.maxqt'.to_sym => 1000,
        :'mlt.mindf'.to_sym => 400,
        :'mlt.mintf'.to_sym => 1,
        :'mlt.boost' => true,
        :'mlt.qf'.to_sym => 'Title^10 Tags^10',
        :'debugQuery' => true,
        :rows => 0 # We just want the parsedquery
    }

    @similatiry_query = {
        :fl => 'AnswererId',
        :defType => 'edismax',
        :stopwords => true,
        :lowercaseOperators => true,
        :rows => 8000
    }

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
          
          puts "parsedquery: #{query}"
          
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
              # Check if answerer actually exists in the database.
              # If he isn't, there's no reason to proceed.
              if (check_answerer_exists(question_answerer_id)['success'])
                # Compare if the original question answerer is also one of the suggested answerers
                if answerers_suggested_ids.include? question_answerer_id
                  puts "GOOD ONE!"
                  open('D:\\good.txt', 'a') { |f|
                    f << query + " " + question.question_id.to_s
                    f <<  "\n"
                  }
                  number_of_good_questions = number_of_good_questions + 1
                else
                  puts "BAD ; Number of answerers suggested #{answerers_suggested_ids.count}"
                  open('D:\\bad.txt', 'a') { |f|
                    f << query + " " + question.question_id.to_s
                    f <<  "\n"
                  }
                  number_of_bad_questions = number_of_bad_questions + 1
                end
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

config_count = 1
for config in configs
  puts
  puts "Configuration #{config_count}: #{config.inspect}"
  puts

  start config
  
  config_count = config_count + 1
end