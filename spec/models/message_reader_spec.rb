require 'spec_helper'
require_relative '../../models/message_reader'

describe "MessageReader" do
  describe "read" do
    it "decode message and downloads image" do
      message = {:website_id => "123", :post_id => "456", :url => "http://www.foo.bar/image.png"}.to_json
      MessageReader.expects(:download_image).with("123", "456", "http://www.foo.bar/image.png")
      MessageReader.read(message)
    end
  end
end