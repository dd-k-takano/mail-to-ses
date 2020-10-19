require 'aws-sdk-s3'
require 'aws-sdk-ses'
require 'json'
require 'logger'

MAIL_FROM = ENV['MAIL_FROM']
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
  raw.split(/\r\n/).each do |line|
    email = line[/[\w+\-.]+@[a-z\d\-.]+\.[a-z]+/i, 0]
    line.sub!(email, MAIL_FROM) if !email.nil?
    data.push(line)
  end

  ses = Aws::SES::Client.new
  ses.send_raw_email(
    source: MAIL_FROM,
    destinations: [ MAIL_TO ],
    raw_message: { data: data.join("\r\n") }
  )
end

# require 'active_support'
# require 'active_support/core_ext'
# event = {}
# lambda_handler(event: event.with_indifferent_access, context: nil)
