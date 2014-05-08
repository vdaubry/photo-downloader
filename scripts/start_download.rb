require 'dotenv'
require 'raven'
require_relative '../config/application'
require_relative "../models/facades/sqs"
require_relative "../models/message_reader"


###########################################################
#
# Configuration
#
###########################################################

Dotenv.load(
      File.expand_path("../../.#{APP_ENV}.env", __FILE__),
      File.expand_path("../../private-conf/.env",  __FILE__))


Raven.configure do |config|
  config.dsn = ENV['RAVEN_URL']
end


###########################################################
#
# Restart instances before 1 hour
#
###########################################################

Thread.new {
  (60*55).times { sleep(1) }
  puts "Shutting down in env #{APP_ENV}"
  system("shutdown -h now") 
}


###########################################################
#
# Start downloading images in queue
#
###########################################################

Facades::SQS.new.poll do |msg|
  Raven.capture do
    MessageReader.new(msg).read
  end
end