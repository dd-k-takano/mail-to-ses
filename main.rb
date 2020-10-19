require 'aws-sdk-s3'
require 'aws-sdk-ses'
require 'json'
require 'logger'

MAIL_DOMAIN = ENV['MAIL_DOMAIN']
MAIL_TO = ENV['MAIL_TO']

def lambda_handler(event:, context:)
  logger = Logger.new(STDOUT)
  logger.level = Logger::DEBUG
  logger.debug event.to_json

  s3 = Aws::S3::Client.new
  response = s3.get_object(
    bucket: event['Records'][0]['s3']['bucket']['name'],
    key: event['Records'][0]['s3']['object']['key']
  )
  raw = response['body'].read()

  data = []
  from = nil
  raw.split(/\r\n/).each do |line|
    receipt = line[/[\w+\-.]+@#{MAIL_DOMAIN}/i, 0]
    line.sub!(receipt, MAIL_TO) if !receipt.nil?
    sender = line[/[\w+\-.]+@[a-z\d\-.]+\.[a-z]+/i, 0]
    if !sender.nil?
      from = "#{sender.sub('@','+')}@#{MAIL_DOMAIN}" if from.nil?
      line.sub!(sender, from)
    end
    data.push(line)
  end

  ses = Aws::SES::Client.new
  ses.send_raw_email(
    source: from,
    destinations: [ MAIL_TO ],
    raw_message: { data: data.join("\r\n") }
  ) if !from.nil?
end

# require 'active_support'
# require 'active_support/core_ext'
# event = {}
# lambda_handler(event: event.with_indifferent_access, context: nil)
