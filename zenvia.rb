require "net/http"

class Zenvia

  attr_reader :alert, :payload

  def initialize(alert)
    @alert = alert
    @payload = alert.payload
  end

  def deliver
    message = "#{payload['severity'].to_s.upcase} #{payload['long_description']}"
    receipts.each { |number| post_to_zenvia(number, message) }
  end

  protected

  def receipts
    numbers = ENV["RECEIPT_NUMBERS"]
    puts("RECEIPT_NUMBERS not defined, ignoring sms alert") and return unless numbers

    numbers.split(",").map(&:strip)
  end

  def post_to_zenvia(phone, message)
    account = ENV['ZENVIA_ACCOUNT']
    code    = ENV['ZENVIA_CODE']
    puts("ZENVIA_ACCOUNT and ZENVIA_CODE not defined, ignoring sms alert") and return unless account || code

    url    = URI.escape("http://system.human.com.br:8080/GatewayIntegration/msgSms.do?dispatch=send&account=#{account}&code=#{code}&to=55#{phone}&msg=#{message}")
    uri    = URI.parse(url)
    result = Net::HTTP.get(uri)

    puts("Send message '#{message}' to #{phone}: #{result}")
    result
  end

end
