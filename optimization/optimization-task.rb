require 'ruby-stackoverflow'
require 'rsolr'
require 'debugger'

require './solr_services.rb'
require './stackoverflow_services.rb'

config = {
  :solr => {
    :url => 'http://23.251.136.35:8983/solr/collection1',
    #:url => 'http://127.0.0.1:8983/solr',
  },
  :stackoverflow => {
    :paginate_query => 30
  },
  :query_parameters => {
    :min_votes => '50', # Used to get only questions where the answerer has a high reputation,
    :similar_questions_count => 100,
    :mlt_fl => 'Body, Title, Tags',
    :mlt_qf => 'Body^2.5 Title^10 Tags^2'
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
    @solr = RSolr.connect :url => @config[:solr][:url]
    
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

          puts "#{counter}. Question #{original_question_id}"
          
          # Get similar questions from Solr
          similar_questions = get_similar_questions_from_solr question
          
          # Find out who answered the similar questions & the real question, from Stackoverflow
          all_questions = similar_questions
          all_questions << question
          #all_questions_answers = get_all_answers_from_stackoverflow all_questions
          all_questions_answers = get_all_answers_from_solr all_questions
          
          # Compare if the original question answerer also answered one of the similar questions
          compareAnswersResult = compare_answers original_question_id, all_questions_answers
          if compareAnswersResult['success']
            puts "GOOD ONE! #{compareAnswersResult['good_questions']}"
            number_of_good_questions = number_of_good_questions + 1
          else
            message = compareAnswersResult['message']
            
            if (message)
              puts "BAD #{message} ; Number of questions #{similar_questions.count}"
            else
              puts "BAD"
            end
            
            number_of_bad_questions = number_of_bad_questions + 1
          end
          
          puts "STATUS: number_of_good_questions: #{number_of_good_questions} | number_of_bad_questions #{number_of_bad_questions}"
        rescue Exception => e
          debugger
          puts "EXCEPTION! ex.: #{e}"
        end
        
        puts
        counter = counter + 1
      end
    end
  end
  
  # Receives a list of all answers including the answer of the "new question" (original_question_id) and the answers of suggested questions.
  # Returns true if the answerer of the original question is in the list of answerers in the suggested questions, otherwise false.
  def compare_answers original_question_id, all_questions_answers
    puts 'INFO: compare_answers'
    
    begin
      # Seperate answers by original question answers and similar questions answers
      similar_questions_answers = []
      original_question_answers = nil
      all_questions_answers.each do |question_id, answers|
        # Original question
        if question_id == original_question_id
          original_question_answers = answers
        else
          similar_questions_answers.concat(answers)
        end
      end
      
      if original_question_answers.nil?
        return {
            'success' => false,
            'message' => "No answers at all for question #{original_question_id}"
          }
      else
        original_question_accepted_answer = original_question_answers.select { |answer| answer.is_accepted }
        # Exactly one accepted answer
        if original_question_accepted_answer.count != 1
          return {
            'success' => false,
            'message' => "No accepted answer for question #{original_question_id}"
          }
        else
          original_question_accepted_answer_owner_id = original_question_accepted_answer[0].owner[:user_id]
          similar_questions_answers_with_same_owner = similar_questions_answers.select do |answer|
            answer.owner[:user_id] == original_question_accepted_answer_owner_id
          end
          if similar_questions_answers_with_same_owner.count > 0
            return {
              'success' => true,
              'good_questions' => similar_questions_answers_with_same_owner
            }
          else
            return {
              'success' => false,
              'message' => "Number of answers #{similar_questions_answers.count}"
            }
          end
        end
      end
    rescue Exception => e
      debugger
      puts "EXCEPTION! ex.: #{e}"
      
      return {
        'success' => false
      }
    end
  end
end

include OptimizationTask

start config
