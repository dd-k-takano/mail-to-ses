require 'aws-sdk-s3'
require 'aws-sdk-ses'
require 'json'
require 'logger'

FORWARD_TO = ENV['FORWARD_TO']

def lambda_handler(event:, context:)
  logger = Logger.new(STDOUT)
  logger.level = Logger::DEBUG
  logger.debug event.to_json

  s3 = Aws::S3::Client.new
  response = s3.get_object(
    bucket: event['Records'][0]['s3']['bucket']['name'],
    key: event['Records'][0]['s3']['object']['key'],
  )
  raw = response['body'].read()

  ses = Aws::SES::Client.new
  ses.send_raw_email(
    source: FORWARD_TO,
    destinations: [ FORWARD_TO ],
    raw_message: { data: raw }
  )
end

# require 'active_support'
# require 'active_support/core_ext'
# event = {}
# lambda_handler(event: event.with_indifferent_access, context: nil)
