require 'rubygems'
require 'sequel'
require 'sinatra'
require 'json'

configure do
  set :public_folder, Proc.new { File.join(root, "static") }
  set :database, ENV['DATABASE_URL'] || 'mysql2://root@localhost:3306/newrelic_webhook'
  DB = Sequel.connect(settings.database)
end

require './alert'
require './zenvia'

def json
  @json ||= begin
              puts "Params: #{params.inspect}"
              if params['alert']
                params['alert']
              else
                body = request.body.read
                puts "Payload: #{body}"
                JSON.parse(body)
              end
            rescue Exception => ex
              puts "Invalid request: #{ex.inspect}"
            end
end

def process_alert
  return unless json

  puts "Alert received: #{json}"
  alert = Alert.new(:created_at => Time.now, :payload => json)
  alert.save
  alert
end

post '/webhook' do
  process_alert

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
    @alerts = Alert.order(:created_at.desc).limit(10)
    erb :index
  else
    puts("Invalid app_key: #{params[:key]}, return empty logs")
    status 200
  end
end
