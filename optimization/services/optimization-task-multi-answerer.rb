require './models/solr_services.rb'
require './models/stackoverflow_services.rb'

module OptimizationTask
  include SolrServices
  include StackoverflowServices

  def start config
    #debugger
    @config = config
    
    # Direct connection
    #url = "http://146.148.24.118:8983/solr/"
    url = "http://localhost:8983/solr/"
    @solr_stackoverflow_indexed = RSolr.connect :url => url + 'collection1'
    @solr_answerer_connection = RSolr.connect :url => url + 'collection2'

    @mlt_request = @config['mlt_params']

    @similatiry_query = @config['similarity_query_params']

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

            response = get_by_parent_id(original_question_id)
            if !response['success']
              puts response['message']
            else
              # The original's question answer documnet
              answer_documents = response['answerers']
              # Check if answerer actually exists in the database.
              # If he isn't, there's no reason to proceed.
              puts "Before filter : #{answer_documents.to_s}"
              answer_documents = filter_answerer_exists(answer_documents, original_question_id)
              puts "After filter : #{answer_documents.to_s}"
              if (answer_documents.size > 1)
                # Compare if the original question answerer is also one of the suggested answerers
                puts answer_documents.size.to_s + "  - The size of the answerers"
                if (answerers_suggested_ids & answer_documents).size > 0
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