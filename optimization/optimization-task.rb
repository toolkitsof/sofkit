require 'ruby-stackoverflow'
require 'rsolr'
require 'debugger'

# Receives a question and returns similar questions from solr.
# We can do this in 2 ways:
# 1) Use Solr's More Like This Mechanism.
# 2) Put the question body in solr's query.
def get_similar_questions_from_solr(question, use_more_like_this = true)
  puts "INFO: get_similar_questions_from_solr"
  
  # Direct connection
  #solr = RSolr.connect :url => 'http://127.0.0.1:8983/solr'
  solr = RSolr.connect :url => 'http://23.251.143.120:8983/solr'
  
  # TODO: Before using more like this, add a check if the item is in solr. If not - index it.
  
  if (use_more_like_this)
    # Send a request to /select
    # TODO: Make sure this params are also used in Blacklight
    request_params = {
      :q => "Id:#{question.question_id}",
      :defType => 'edismax',
      :mlt => 'true',
      :'mlt.fl'.to_sym => 'Body, Title',
      :'mlt.qf'.to_sym => 'Body^2.5 Title^10',
      # :'mlt.qf' => 'Body_t^10 Title_t^10',
      :'mlt.count'.to_sym => 50
    }
    
    solr_response = solr.get 'select', :params => request_params
    
    similar_docs_from_solr = solr_response["moreLikeThis"][question.question_id.to_s]
    if similar_docs_from_solr.nil?
      similar_questions = []
    else
      similar_questions = similar_docs_from_solr["docs"]
    end
  else
    # Send a request to /select
    # TODO: Make sure this params are also used in Blacklight
    request_params = {
      :q => question.body,
      :defType => 'edismax',
      :qf => 'Body^10 Title^10',
      # :qf => 'Body_t^10 Title_t^10',
      :rows => 30
    }
    
    solr_response = solr.get 'select', :params => request_params

    # Manipulate results
    similar_questions = solr_response["response"]["docs"]
  end
  
  
end

# Receives a list of all answers including the answer of the "new question" (original_question_id) and the answers of suggested questions.
# Returns true if the answerer of the original question is in the list of answerers in the suggested questions, otherwise false.
def compare_answers(original_question_id, all_questions_answers)
  puts 'INFO: compare_answers'
  
  begin
    # Seperate answers by original question answers and similar questions answers
    similar_questions_answers = []
    for question_answers in all_questions_answers
      question_id = question_answers.question_id
      
      # Original question
      if question_id == original_question_id
        original_question_answers = question_answers.answers
      else
        similar_questions_answers.concat(question_answers.answers)
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
        similar_questions_answers_with_same_owner = similar_questions_answers.select { |answer| answer.ow
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

# Will get all answers from Stackoverflow, if after the first query there is still more it will get them too
def get_all_answers_from_stackoverflow(questions_ids)
  puts "INFO: get_all_answers_from_stackoverflow"

  questions_answers = []
  page = 1
  has_more = true
  
  while has_more do
    response = RubyStackoverflow.answers_of_questions(questions_ids, :page => page )
    questions_answers.concat response.data
    page = page + 1
    
    # Decide if there is more to fetch by response
    has_more = response.has_more
  end
  
  return questions_answers
end

puts "Getting questions from Stackoverflow.."

# Get random questions from Stackoverflow
questions = RubyStackoverflow.questions({:order => 'asc', :filter => 'withBody' }).data

for question in questions
  begin
    original_question_id = question.question_id

    puts "Question #{original_question_id}"
    
    # Get similar questions from Solr
    similar_questions = get_similar_questions_from_solr(questionner[:user_id] == original_question_accepted_answer_owner_id }
        if similar_questions_answers_with_same_owner.count > 0)
    similar_questions_ids = similar_questions.map { |question| question['Id'] }
    
    # Find out who answered the similar questions & the real question, from Stackoverflow
    all_questions_ids = similar_questions_ids.dup
    all_questions_ids << original_question_id.to_s
    all_questions_answers = get_all_answers_from_stackoverflow(all_questions_ids)
    
    # Compare if the original question answerer also answered one of the similar questions
    compareAnswersResult = compare_answers(original_question_id, all_questions_answers)
    if compareAnswersResult['succees']
      puts "GOOD #{compareAnswersResult['good_questions']}"
    else
      message = compareAnswersResult['message']
      
      if (message)
        puts "BAD #{message} ; Number of questions #{similar_questions.count}"
      else
        puts "BAD"
      end
    end
  rescue Exception => e
    puts "EXCEPTION! ex.: #{e}"
  end
  
  puts
end
