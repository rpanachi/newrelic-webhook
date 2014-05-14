require "net/http"

class Zenvia

  attr_reader :alert

  def initialize(alert)
    @alert = alert
  end

  def deliver
    message = "#{alert.severity.upcase} #{alert.application_name}: #{alert.long_description}"
    receipts.each { |number| post_to_zenvia(number, message) }
  end

  protected

  def receipts
    ENV["RECEIPT_NUMBERS"].split(",").map(&:strip)
  end

  def post_to_zenvia(phone, message)
    account = ENV['ZENVIA_ACCOUNT']
    code    = ENV['ZENVIA_CODE']

    url = URI.escape("http://system.human.com.br:8080/GatewayIntegration/msgSms.do?dispatch=send&account=#{account}&code=#{code}&to=55#{phone}&msg=#{message}")
    uri = URI.parse(url)
    Net::HTTP.get(uri)
  end

end
