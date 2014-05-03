require_relative "image_downloader"

class MessageReader
  def self.read(msg)
    json_msg = JSON.parse(msg)
    self.download_image(json_msg["website_id"], json_msg["post_id"], json_msg["url"])
  end

  def self.download_image(website_id, post_id, url)
    imageDownloader = ImageDownloader.new.build_info(id, @post_id, url)
    if imageDownloader.key
      pp "Save #{imageDownloader.key}"
      imageDownloader.download(page_image)
      sleep(1)
    end
  end
end
