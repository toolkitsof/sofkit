require 'ruby-stackoverflow'
require 'rsolr'
require 'debugger'

require './models/settings.rb'
#require './services/optimization-task.rb'
require './services/optimization-task-multi-answerer.rb'

include OptimizationTask

puts "INFO: Loading configuration"

Settings.load! "config.rb"

static_config = Settings.configs['static']
dynamic_config = Settings.configs['dynamic']

puts "INFO: Initializing engine"

# Initialize SofyEngine
initialize_engine static_config

puts "INFO: Getting questions for optimization"

#response = get_questions_from_stack_overflow
response = get_questions_from_solr

if !response['success']
  puts response['message']
else
  @questions = response['questions']

  def optimize_start partial_config
    update_engine_config partial_config
    number = start(@questions)
    puts number
    
    return number
  end
  
  config_count = 1
  for partial_config in dynamic_config
    puts
    puts "Configuration #{config_count}: #{partial_config.inspect}"
    puts
    
    optimize_start partial_config
    
    config_count = config_count + 1
  end
end