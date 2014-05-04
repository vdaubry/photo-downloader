require 'dotenv'
require_relative "../models/facades/sqs"
require_relative "../models/message_reader"

Dotenv.load(
      File.expand_path("../../.#{APP_ENV}.env", __FILE__),
      File.expand_path("../../private-conf/.env",  __FILE__))

Facades::SQS.new.poll do |msg|
  MessageReader.new(msg).read
end