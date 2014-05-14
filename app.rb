require 'rubygems'
require 'sequel'
require 'sinatra'
require 'json'

configure do
  set :public_folder, Proc.new { File.join(root, "static") }
  set :database, ENV['HEROKU_POSTGRESQL_GREEN_URL'] || ENV['DATABASE'] || 'mysql2://root@localhost:3306/newrelic_webhook_zenvia'
  DB = Sequel.connect(settings.database)
end

require './deployment'
require './alert'

get '/' do
  @deployments = Deployment.order(:created_at.desc)
  @alerts = Alert.order(:created_at.desc)
  erb :index
end

post '/webhook' do
  body = request.body.read
  json = JSON.parse(body)

  if json['severity']
    alert = Alert.new(json)
    alert.save
  end

  if json['revision']
    deployment = Deployment.new(json)
    deployment.save
  end

  status 200
end
