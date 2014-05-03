require_relative "facades/sqs"
require_relative "message_reader"

Facades::SQS.new.poll do |msg|
  MessageReader.read(msg)
end