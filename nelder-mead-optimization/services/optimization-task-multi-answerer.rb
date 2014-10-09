require './../sofy-engine/lib/sofy_engine.rb'

module OptimizationTask
  include SofyEngine
  
  def start_get_answerers questions
    
    puts "Received #{questions.count} questions"
    
    number_of_good_questions = 0
    number_of_bad_questions = 0
    
    # Iterate chosen questions
    counter = 1
    for question in questions
      # To give solr time to GC and avoid OutOfMemory exception
      #sleep(2)
      
      original_question_id = question.question_id
      original_question_accepted_answer_id = question.accepted_answer_id
    
      # Info
      puts "#{counter}. Question #{original_question_id}"

      response = get_by_parent_id(original_question_id)
      
      if !response['success']
        puts response['message']
      else
        begin
          # The original's question answer documnet
          answer_documents = response['answerers']
          # Check if answerer actually exists in the database.
          # If he isn't, there's no reason to proceed.
          puts "\nBefore filter :" + answer_documents.to_s
          answer_documents = filter_answerer_exists(answer_documents, original_question_id)
          puts "\nAfter" + answer_documents.to_s
          
          if (answer_documents.size > 0)
    
            # Call to SofyEngine
            (answerers_suggested_ids, query) = return_answerers_ids question, false
            
            # Can happen if sofy throws an exception
            if query == nil
              error_msg = answerers_suggested_ids
              # Write to log
              open('errors.txt', 'a') { |f|
                f << "Question Id: #{question.question_id.to_s} \n #{error_msg} \n"
              }
            # Can happen only if no documents returns (config is high on values)
            elsif query == ''
              puts "BAD ; No documents returned on initial query from collection1"
              open('bad.txt', 'a') { |f|
                f << "Question id: #{question.question_id.to_s} #{query} \n"
              }

              number_of_bad_questions = number_of_bad_questions + 1
            else
              response = get_by_parent_id(original_question_id)
              
              if !response['success']
                puts response['message']
              else
            
                # Compare if the original question answerer is also one of the suggested answerers
                #if answerers_suggested_ids.include? question_answerer_id
                
                # Accept as a good one even if the answerer is not the accepted answerer
                puts answer_documents.size.to_s + "  - The size of the answerers"
                if (answerers_suggested_ids & answer_documents).size > 0
                  puts "GOOD ONE!"
                  open('good.txt', 'a') { |f|
                    f << query + " " + question.question_id.to_s
                    f <<  "\n"
                  }
                  number_of_good_questions = number_of_good_questions + 1
                else
                  puts "BAD ; Number of answerers suggested #{answerers_suggested_ids.count}"
                  open('bad.txt', 'a') { |f|
                    f << "Question id: #{question.question_id.to_s} #{query} \n"
                  }

                  number_of_bad_questions = number_of_bad_questions + 1
                end
              end
            end
          end
        rescue Exception => e
          puts "EXCEPTION! ex.: #{e}"
          
          error_msg = "Exception probably in initial query"
          # Write to log
          open('errors.txt', 'a') { |f|
            f << "Question Id: #{question.question_id.to_s} \n #{error_msg} \n"
          }
        end
      end
      
      puts "STATUS: number_of_good_questions: #{number_of_good_questions} | number_of_bad_questions #{number_of_bad_questions}"
      puts
      counter = counter + 1
    end
    
    return number_of_good_questions, number_of_bad_questions
  end
  
  def start_get_questions answerers_ids

  end
end