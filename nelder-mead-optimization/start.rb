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

#response = get_questions_from_stack_overflow
response = get_questions_from_solr
#response = get_question_from_solr 17641074

if !response['success']
  puts response['message']
else
  @questions = response['questions']

  def optimize_start *args
    sleep(5)
    
    # A solution for when nelder mead reaches a negative number
    args.each do |a|
      if a < 0
        return 999999999999
      end
    end
    
    parsed_partial_config = {
      'mlt.mintf' => args[0].to_i,
      'mlt.mindf' => args[1].to_i,
      'mlt.minwl' => args[2].to_i,
      'mlt.maxqt' => args[3].to_i,
      'titleBoost' => args[4],
      'tagsBoost' => args[5],
      'bodyBoost' => args[6]
    }
  
    update_engine_config parsed_partial_config
    number = start(@questions)
    puts
    puts "##############################################"
    puts
    puts "#{Time.now} Result for config #{parsed_partial_config} is: #{number}"
    puts
    puts "##############################################"
    puts
    
    open('results.txt', 'a') { |f|
      f << "#{Time.now} Result for config #{parsed_partial_config} is: #{number} \n"
    }
    
    return number
  end

#=begin
  #proc=lambda{|a, b, c|sin(a)*cos(b)*sin(c)}
  #optimium=proc.dhsmplx([[0, 0, 0], [1, 0, 0], [0, 1, 0], [0, 0, 1]])  
  proc = lambda(&method(:optimize_start))
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
	
    optimize_start partial_config[0], partial_config[1], partial_config[2], partial_config[3]
    
    config_count = config_count + 1
  end
=end
end