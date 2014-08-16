require 'sinatra'
require 'ruby-stackoverflow'
require 'rsolr'
require 'debugger'

require './models/settings.rb'
require './../sofy-engine/sofy_engine.rb'

include SofyEngine

def initialize_server
  get '/return_answerers_ids_from_server' do
    headers['Access-Control-Allow-Origin'] = 'chrome-extension://ealapgbcdenhandbmnehdikdjmnhflge'
    
    id = params[:id]
    answerers_suggested_ids = return_answerers_ids_from_server id
    
    puts "Returning: #{answerers_suggested_ids}"
    
    return answerers_suggested_ids.to_json
  end
end

def return_answerers_ids_from_server question_id
  # Initialize Engine
  Settings.load! "config.rb"
  configs = Settings.configs
  config = configs.first
  initialize_engine config

  # Get answerers
  response = get_question_from_stack_overflow question_id
  (answerers_suggested_ids, query) = return_answerers_ids response['question']
  
  return answerers_suggested_ids
end

initialize_server
#return_answerers_ids_from_server 1961020