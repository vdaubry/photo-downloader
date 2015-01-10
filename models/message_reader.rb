require_relative "image_downloader"
require_relative "../hosts/host_factory"

class MessageReader

  def initialize(msg=nil)
    @msg = msg
  end

  def read
    puts "found SQS message : #{@msg}"
    json_msg = JSON.parse(@msg)
    download_image(json_msg["website_id"], json_msg["post_id"], json_msg["image_url"], DateTime.parse(json_msg["scrapped_at"]))
  end

  #Maybe we could send a HEAD request and check content type of response ?
  def direct_link_to_image?(url)
    regexp = Regexp.new('^https?://(?:[a-z\-]+\.)+[a-z]{2,6}(?:/[^/#?]+)+\.(?:jpg|gif|png|jpeg|JPEG|JPG|PNG|GIF)$')
    (url =~ regexp).present?
  end

  def download_image(website_id, post_id, url, scrapped_at)
    image_downloader = ImageDownloader.new.build_info(website_id, post_id, url, scrapped_at)
    if image_downloader.key.nil?
      puts "could not determine image key, invalid url : #{url}"
      return
    end

    if direct_link_to_image?(url)
      pp "Save #{image_downloader.key}"
      image_downloader.download(nil, require_proxy(url))
    else
      page_image = HostFactory.create_with_host_url(url).page_image rescue nil
      image_downloader.download(page_image)
    end

    sleep(1) unless ENV['TEST']
  end

  def require_proxy(url)
    hosts_with_proxy = YAML.load_file("private-conf/hosts_conf.yml")["hosts_with_proxy"]
    host = URI(URI.encode(url)).host
    hosts_with_proxy.include? host
  end
end
