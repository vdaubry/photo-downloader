require 'aws-sdk'

module Facades
  class SQS

    attr_accessor :queue

    def initialize
      AWS.config({
      :access_key_id => ENV["AWS_ACCESS_KEY_ID"],
      :secret_access_key => ENV["AWS_SECRET_ACCESS_KEY"]
      })

      sqs = AWS::SQS.new 

      @queue = begin
                sqs.queues.named(ENV["QUEUE_NAME"])
              rescue AWS::SQS::Errors::NonExistentQueue => e
                sqs.queues.create(ENV["QUEUE_NAME"])
              end
    end

    def send(message)
      @queue.send_message("#{message}") unless message.nil?
    end

    def poll
      @queue.poll do |received_message| 
        yield(received_message.body)
      end
    end
  end
end