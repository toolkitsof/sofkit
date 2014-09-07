require 'sinatra'
require 'ruby-stackoverflow'
require 'rsolr'

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
  
  get '/return_questions_ids_from_server' do
    headers['Access-Control-Allow-Origin'] = 'chrome-extension://ealapgbcdenhandbmnehdikdjmnhflge'
    
    id = params[:id]
    questions_suggested_ids = return_questions_ids_from_server id
    
    puts "Returning: #{questions_suggested_ids}"
    
    return questions_suggested_ids.to_json
  end
end

def before_filter_init
  # Initialize Engine
  Settings.load! "config.rb"
  configs = Settings.configs
  config = configs.first
  
  initialize_engine config
end

def return_answerers_ids_from_server question_id
  before_filter_init

  # Get answerers
  response = get_question_from_stack_overflow question_id
  question_id = response['question']
  (answerers_suggested_ids, query) = return_answerers_ids question_id, false
  
  return answerers_suggested_ids
end

def return_questions_ids_from_server user_id
  before_filter_init
  
  response = get_questionids_by_mlt user_id
  
  # TODO: extract here questionsids from response
  
  questionsids = [11111]
  
  return questionsids
end


#initialize_server

#return_answerers_ids_from_server 4550770

return_questions_ids_from_server 485911