require 'ruby-stackoverflow'
require 'rsolr'
require 'debugger'
require './services/stat.rb'
require './services/downhill-simplex.rb'

require './models/settings.rb'
#require './services/optimization-task.rb'
require './services/optimization-task-multi-answerer.rb'

include OptimizationTask
include Math

# Configuration

puts "INFO: Loading configuration"

Settings.load! "config.rb"

static_config = Settings.configs['static']
dynamic_config = Settings.configs['dynamic']

# Initialize engine

puts "INFO: Initializing engine"

# Initialize SofyEngine
initialize_engine static_config

puts "INFO: Getting questions for optimization"

# Use this to optimize get questions

#response = get_questions_from_stack_overflow
response = get_questions_from_solr
#response = get_question_from_solr 22969090


# Use this to optimize get answerers

#response = get_answerers_ids_from_solr

if !response['success']
  puts response['message']
else
  # Use this to optimize get questions
  @questions = response['questions']

  # Use this to optimize get answerers
  #@answerers_ids = response['answerers_ids']  
  
  def optimize_start_get_answerers *args
    sleep(5)
    
    # A solution for when nelder mead reaches a negative number
    args.each do |a|
      if a < 0
        return 999999999999
      end
    end
    
    mlt_parsed_partial_config = {
      'mlt.mindf' => args[0].to_i,
      'mlt.minwl' => args[1].to_i,
      'mlt.maxqt' => args[2].to_i,
      'titleBoost' => args[3],
      'tagsBoost' => args[4]
    }
    
    # Use this to optimize get questions
    body_query_answerer_parsed_partial_config = {
      #'mindf' => args[5].to_i,
      #'bodyboost' => args[6]
    }
    
    # Use this to optimize get answerers
    body_query_question_parsed_partial_config = {
      'mindf' => args[5].to_i,
      'bodyboost' => args[6]
    }
  
    update_engine_config mlt_parsed_partial_config, body_query_answerer_parsed_partial_config, body_query_question_parsed_partial_config
    (number_of_good_questions, number_of_bad_questions) = start_get_answerers(@questions)
    number_of_questions = number_of_good_questions + number_of_bad_questions
    puts
    puts "##############################################"
    puts
    puts "#{Time.now} Result for config #{mlt_parsed_partial_config} AND #{body_query_answerer_parsed_partial_config} AND #{body_query_question_parsed_partial_config} is: #{number_of_bad_questions} / #{number_of_questions}"
    puts
    puts "##############################################"
    puts
    
    open('results.txt', 'a') { |f|
      f << "#{Time.now} Result for config #{mlt_parsed_partial_config} AND #{body_query_answerer_parsed_partial_config} AND #{body_query_question_parsed_partial_config} is: #{number_of_bad_questions} / #{number_of_questions} \n"
    }
    
    return number_of_bad_questions
  end

  def optimize_start_get_questions *args
    sleep(5)
    
    # A solution for when nelder mead reaches a negative number
    args.each do |a|
      if a < 0
        return 999999999999
      end
    end
    
    mlt_parsed_partial_config = {
      'mlt.mindf' => args[0].to_i,
      'mlt.minwl' => args[1].to_i,
      'mlt.maxqt' => args[2].to_i,
      'titleBoost' => args[3],
      'tagsBoost' => args[4]
    }
    
    # Use this to optimize get questions
    body_query_answerer_parsed_partial_config = {
      'mindf' => args[5].to_i,
      'bodyboost' => args[6]
    }
    
    # Use this to optimize get answerers
    body_query_question_parsed_partial_config = {
      #'mindf' => args[5].to_i,
      #'bodyboost' => args[6]
    }
  
    update_engine_config mlt_parsed_partial_config, body_query_answerer_parsed_partial_config, body_query_question_parsed_partial_config
    (number_of_good_questions, number_of_bad_questions) = start_get_questions(@answerers_ids)
    number_of_questions = number_of_good_questions + number_of_bad_questions
    puts
    puts "##############################################"
    puts
    puts "#{Time.now} Result for config #{mlt_parsed_partial_config} AND #{body_query_answerer_parsed_partial_config} AND #{body_query_question_parsed_partial_config} is: #{number_of_bad_questions} / #{number_of_questions}"
    puts
    puts "##############################################"
    puts
    
    open('results.txt', 'a') { |f|
      f << "#{Time.now} Result for config #{mlt_parsed_partial_config} AND #{body_query_answerer_parsed_partial_config} AND #{body_query_question_parsed_partial_config} is: #{number_of_bad_questions} / #{number_of_questions} \n"
    }
    
    return number
  end
  
  
#=begin
  #proc=lambda{|a, b, c|sin(a)*cos(b)*sin(c)}
  #optimium=proc.dhsmplx([[0, 0, 0], [1, 0, 0], [0, 1, 0], [0, 0, 1]])

  # Use this to optimize get answerers
  proc = lambda(&method(:optimize_start_get_answerers))
  
  # Use this to optimize get questions
  #proc = lambda(&method(:optimize_start_get_questions))
  
  optimium = proc.dhsmplx(dynamic_config)
  
  puts "Optimium History: "
  puts optimium
  puts "Optimium: "
  puts optimium[-1][0]
  puts "Optimized function value: "
  puts proc.call(*optimium[-1][0])
#=end
  # Used before nelder mead just to run all configurations one after another and watch results
=begin
  config_count = 1
  for partial_config in dynamic_config
    puts
    puts "Configuration #{config_count}: #{partial_config.inspect}"
    puts
	
    optimize_start_get_answerers partial_config[0], partial_config[1], partial_config[2], partial_config[3]
    
    config_count = config_count + 1
  end
=end
end