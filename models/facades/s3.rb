require 'aws-sdk'

module Facades
  class S3
    def initialize
      AWS.config({
      :access_key_id => ENV["AWS_ACCESS_KEY_ID"],
      :secret_access_key => ENV["AWS_SECRET_ACCESS_KEY"]
      })

      s3 = AWS::S3.new 
      @bucket = s3.buckets[ENV["S3_BUCKET"]]
    end

    def key_path(key)
      timestamp = key.split("_").first.to_i
      folder1 = timestamp / 10000000
      folder2 = timestamp / 10000
      folder3 = timestamp / 10
      "#{folder1}/#{folder2}/#{folder3}/#{key}"
    end

    def image_path(key)
      "/image/#{key_path(key)}"
    end

    def thumbnail_path(key, format)
      "/thumbnail/#{format}/#{key_path(key)}"
    end

    def write_image(key, data)
      unless ENV['TEST']
        obj = @bucket.objects[key]
        obj.write(Pathname.new(image_path(key)), data)
      end
    end

    def write_thumbnail(key, format, data)
      unless ENV['TEST']
        obj = @bucket.objects[key]
        obj.write(Pathname.new(thumbnail_path(key, format)), data)
      end
    end
  end
end