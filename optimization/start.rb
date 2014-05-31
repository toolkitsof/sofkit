require 'ruby-stackoverflow'
require 'rsolr'
require 'debugger'

require './models/settings.rb'
#require './services/optimization-task.rb'
require './services/optimization-task-multi-answerer.rb'

include OptimizationTask

#debugger
Settings.load! "config.rb"

configs = Settings.configs

config_count = 1
for config in configs
  puts
  puts "Configuration #{config_count}: #{config.inspect}"
  puts

  start config
  
  config_count = config_count + 1
end