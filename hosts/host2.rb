require_relative "generic_host"

class Host2 < GenericHost

  def all_images
    browser = Mechanize.new.get(@host_url)
    images = browser.images.select {|i| (i.url.to_s.downcase =~ /jpg|jpeg|png|gif|JPG|JPEG|GIF|PNG/).present? }
    images.select! {|s| s.url.to_s.include?("download") }
    images
  end

end