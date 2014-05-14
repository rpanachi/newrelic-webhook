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

def json
  @json ||= (JSON.parse(request.body.read) rescue nil)
end

def process_alert
  if json['severity']
    puts "Alert received: #{json}"
    alert = Alert.new(json)
    alert.save
    alert
  end
end

def process_deployment
  if json['revision']
    puts "Deployment received: #{json}"
    deployment = Deployment.new(json)
    deployment.save
    deploymeny
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

get '/' do
  app_key = ENV['APP_KEY']
  puts("APP_KEY not defined, returning empty logs") unless app_key

  if params[:key] == app_key
    @deployments = Deployment.order(:created_at.desc).limit(10)
    @alerts = Alert.order(:created_at.desc).limit(10)
    erb :index
  else
    puts("Invalid app_key: #{params[:key]}, return empty logs")
    status 200
  end
end
