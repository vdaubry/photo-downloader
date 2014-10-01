require "spec_helper"
require_relative "../../../models/facades/s3"

describe "Facades::S3" do
  describe "key_path" do
    it  { Facades::S3.new.key_path("1410986060_7dabd6308611804.jpg").should == "141/141098/141098606/1410986060_7dabd6308611804.jpg" }
  end

  describe "image_path" do
    it  { Facades::S3.new.image_path("1410986060_7dabd6308611804.jpg").should == "image/141/141098/141098606/1410986060_7dabd6308611804.jpg" }
  end

  describe "thumbnail_path" do
    it  { Facades::S3.new.thumbnail_path("1410986060_7dabd6308611804.jpg", "300x300").should == "thumbnail/300x300/141/141098/141098606/1410986060_7dabd6308611804.jpg" }
  end
end