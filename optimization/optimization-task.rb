require 'ruby-stackoverflow'
require 'rsolr'
require 'debugger'

config = {
  :solr => {
    :url => 'http://23.251.136.35:8983/solr',
    #:url => 'http://127.0.0.1:8983/solr',
    :similar_questions_count => 100
  },
  :stackoverflow => {
    :paginate_query => 30,
    :min_votes => '50'
  }
}

puts
puts "Configuration: #{config.inspect}"
puts

module OptimizationTask
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
      for question in questions
        begin
          original_question_id = question.question_id

          puts "Question #{original_question_id}"
          
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
      end
    end
  end
  
  def get_questions_from_stack_overflow
    puts "Getting questions from Stackoverflow.."
    
    # Get random questions from Stackoverflow
    response = RubyStackoverflow.questions({:order => 'asc', :filter => 'withBody', :sort => 'votes', :min => @config[:stackoverflow][:min_votes] })
    if response.data == nil
      return {
        'success' => false,
        'message' => response.inspect
      }
    else
      return {
        'success' => true,
        'questions' => response.data
      }
      
    end
  end
  
  def get_questions_from_solr
    min_votes = @config[:stackoverflow][:min_votes]
  
    # Send a request to /select
    # TODO: Make sure this params are also used in Blacklight
    request_params = {
      :q => "*:*",
      :fl => 'Id, AcceptedAnswerId',
      :defType => 'edismax',
      :fq => "+Score:#{min_votes} -AcceptedAnswerId:\"\"",
      :rows => 50
    }
    
    solr_response = @solr.get 'select', :params => request_params
  
    # Format response as a RubyStackoverflow Question object
    questions = solr_response['response']['docs'].map { |doc| RubyStackoverflow::Client::Question.new({
        :'question_id' => doc['Id'].to_i,
        :'accepted_answer_id' => doc['AcceptedAnswerId'].to_i
      })
    }
  
    return {
      'success' => true,
      'questions' => questions
    }
  end

  # Receives a question and returns similar questions from solr.
  # We can do this in 2 ways:
  # 1) Use Solr's More Like This Mechanism.
  # 2) Put the question body in solr's query.
  def get_similar_questions_from_solr question, use_more_like_this = true
    puts "INFO: get_similar_questions_from_solr"
    
    # TODO: Before using more like this, add a check if the item is in solr. If not - index it.
    
    if (use_more_like_this)
      # Send a request to /select
      # TODO: Make sure this params are also used in Blacklight
      request_params = {
        :q => "Id:#{question.question_id}",
        :defType => 'edismax',
        :mlt => 'true',
        :'mlt.fl'.to_sym => 'Body, Title',
        #:'mlt.qf'.to_sym => 'Body^2.5 Title^10',
        :'mlt.qf' => 'Body_t^10 Title_t^10',
        :'mlt.count'.to_sym => @config[:solr][:similar_questions_count]
      }
      
      solr_response = @solr.get 'select', :params => request_params
      
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
      
      solr_response = @solr.get 'select', :params => request_params

      # Manipulate results
      similar_questions = solr_response["response"]["docs"]
    end
    
    similar_questions = similar_questions.map { |doc| RubyStackoverflow::Client::Question.new({
        :'question_id' => doc['Id'].to_i,
        :'accepted_answer_id' => doc['AcceptedAnswerId'].to_i
      })
    }
    
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

  # Will get all answers from Stackoverflow, if after the first query there is still more it will get them too
  def get_all_answers_from_stackoverflow questions
    puts "INFO: get_all_answers_from_stackoverflow"
    
    questions_ids = questions.map { |question| question.question_id }

    # Used to gather all answers
    questions_answers = {}
    # Sof can't handle all the questions_ids at once so we paginate the questions_ids into a bulk of requests
    questions_ids_page = 1
    
    # Two methods used to return next and previous pages
    def previous_page page
      (page - 1) * @config[:stackoverflow][:paginate_query]
    end
    
    def next_page page
      (page * @config[:stackoverflow][:paginate_query]) - 1
    end
    
    # Keep iterating until no more questions
    while questions_ids.count > previous_page(questions_ids_page) do
      questions_ids_subset = questions_ids[previous_page(questions_ids_page)..next_page(questions_ids_page)]
      
      # Stackoverflow also paginates each request even with 50 questions_ids
      page = 1
      has_more = true
      
      while has_more do
        response = RubyStackoverflow.answers_of_questions(questions_ids_subset, :page => page )
        
        # Format data as hierarchical structure where the key is the question_id
        for question in response.data
          question_id = question.question_id
        
          # Question answers received previously
          if questions_answers[question_id]
            questions_answers[question_id].concat question.answers
          else
            questions_answers[question_id] = question.answers
          end
        end
        
        page = page + 1
        
        # Decide if there is more to fetch by response
        has_more = response.has_more
      end
      
      questions_ids_page = questions_ids_page + 1
    end
    
    return questions_answers
  end
  
  # Will get all answers from solr
  def get_all_answers_from_solr questions
    puts "INFO: get_all_answers_from_solr"

    # Used to gather all answers
    questions_answers = {}
    
    
    questions_dictionary = {}
    questions.each do |question|
      questions_dictionary[question.question_id] = question
    end
    
    questions_ids = questions.map { |question| question.question_id }
    questions_ids_parsed = questions_ids.join(" OR ")
    
    # Send a request to /select
    # TODO: Make sure this params are also used in Blacklight
    request_params = {
      :q => "ParentId:(#{questions_ids_parsed})",
      :defType => 'edismax',
      :fq => 'AnswerCount:""',
      :rows => 1000
    }
    
    solr_response = @solr.get 'select', :params => request_params
    
    questions_answers = {}
    solr_response["response"]["docs"].each do |answer|
      question_id = answer['ParentId'].to_i
      question = questions_dictionary[question_id]
      is_accepted = question.accepted_answer_id == answer['Id'].to_i
      
      questions_answers[question_id] = [] if questions_answers[question_id].nil?
      
      # Format response as a RubyStackoverflow Answer object
      questions_answers[question_id] << RubyStackoverflow::Client::Answer.new({
        :'is_accepted' => is_accepted,
        :'owner' => {
          :'user_id' => answer['OwnerUserId'].to_i
        }
      })
    end
    
    return questions_answers
  end
end

include OptimizationTask

start config
