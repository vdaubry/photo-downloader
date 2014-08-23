require 'rubygems'
require 'bundler/setup'
require 'httparty'
require 'active_model'
require_relative '../config/application'
require_relative 'api_helper'

class Image
  include HTTParty
  extend ApiHelper

  def self.create(website_id, post_id, source_url, key, status, image_hash, width, height, file_size, scrapped_at)
    set_base_uri
    retry_call do
      
      resp = self.post("/websites/#{website_id}/posts/#{post_id}/images.json", :body => {:image => 
        {:source_url => source_url, 
          :key => key, 
          :status => status, 
          :image_hash => image_hash, 
          :width => width, 
          :height => height, 
          :file_size => file_size, 
          :scrapped_at => scrapped_at}})

      if resp.code == 422
        puts "API reject image with errors : #{resp["errors"]}"
        return
      elsif resp.code != 200
        puts "API image post failed with response : #{resp.code}"
        return
      end
      Image.new(resp["image"]) if resp["image"]
    end
  end

  def initialize(json)
    @json = json
  end

  def key
    @json["key"]
  end
end