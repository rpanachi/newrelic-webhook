require 'rubygems'
require 'sequel'
require 'sinatra'
require 'json'

configure do
  set :public_folder, Proc.new { File.join(root, "static") }
  set :database, ENV['DATABASE_URL'] || 'mysql2://root@localhost:3306/newrelic_webhook_zenvia'
  DB = Sequel.connect(settings.database)
end

require './deployment'
require './alert'
require './zenvia'

# get '/' do
#   @deployments = Deployment.order(:created_at.desc)
#   @alerts = Alert.order(:created_at.desc)
#   erb :index
# end

def json
  @json ||= (JSON.parse(request.body.read) rescue nil)
end

def process_alert
  if json['severity']
    alert = Alert.new(json)
    alert.save
  end
end

def process_deployment
  if json['revision']
    deployment = Deployment.new(json)
    deployment.save
  end
end

post '/webhook' do
  process_alert
  process_deployment

  status 200
end

post '/deploy' do
  process_deployment

  status 200
end

post '/sms' do
  if (alert = process_alert)
    zenvia = Zenvia.new(alert)
    zenvia.deliver
  end

  status 200
end
