module SofyEngine
  module StackoverflowServices
    # Returns random (with some constrains) questions from stack overflow
    def get_questions_from_stack_overflow
      puts "Getting questions from Stackoverflow.."
      
      # Get random questions from Stackoverflow
      response = RubyStackoverflow.questions({:order => 'asc', :filter => 'withBody', :sort => 'votes', :min => 50 })
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
    
    # Returns random (with some constrains) questions from stack overflow
    def get_question_from_stack_overflow question_id
      puts "Getting question #{question_id} from Stackoverflow.."
      
      # Get question from Stackoverflow
      response = RubyStackoverflow.questions_by_ids([question_id],{:filter => 'withBody'})
      
      if response.data == nil
        return {
          'success' => false,
          'message' => response.inspect
        }
      else
        return {
          'success' => true,
          'question' => response.data.first
        }
        
      end
    end

    # Receives questions
    # Returns all answers from solr
    # (if after the first query there is still more it will get them too, sof indicates it by the has_more key)
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
    
  end
end