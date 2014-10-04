require 'open-uri'
require 'open_uri_redirections'
require 'fastimage'
require 'mini_magick'
require 'active_support/time'
require 'benchmark'
require 'progressbar'
#require 'image_optim'
require_relative 'facades/s3'
require_relative 'image'

class ImageDownloader
  TO_SORT_STATUS="TO_SORT_STATUS"
  THUMBNAIL_FORMAT="300x300"

  attr_accessor :source_url, :key, :status, :image_hash, :width, :height, :file_size, :website_id, :post_id, :scrapped_at

  def initialize(key=nil)
    @key = key
  end

  def key_from_url(source_url)
    path = File.basename(URI.parse(source_url).path)
    ext = File.extname(path)

    if [".html", ".htm"].include?(ext)
      path = path.split(ext).first
    end

    if File.extname(path)==""
      path = path+".jpg"
    end    

    DateTime.now.to_i.to_s + "_" + path.gsub('-', '_').gsub(/[^0-9A-Za-z_\.]/, '')
  end

  def build_info(website_id, post_id, source_url, scrapped_at)
    @website_id = website_id
    @post_id = post_id
    @source_url = source_url
    @scrapped_at = scrapped_at
    begin
      @key = key_from_url(source_url)
    rescue URI::InvalidURIError => e
      puts e.to_s
    end
    @status = ImageDownloader::TO_SORT_STATUS
    self
  end


  #TODO : utiliser TmpDir
  def image_save_path
    "tmp/images/#{@key}"
  end

  #TODO : utiliser TmpDir
  def thumbnail_save_path
    "tmp/images/thumbnails/300/#{@key}"
  end  

  def generate_thumb
    image = MiniMagick::Image.open(image_save_path) 
    image.resize THUMBNAIL_FORMAT
    image.write thumbnail_save_path
  end

  def set_image_info
    image_file = File.read(image_save_path)
    self.image_hash = Digest::MD5.hexdigest(image_file)
    image_size = FastImage.size(image_save_path)
    if image_size
      self.width = image_size[0]
      self.height = image_size[1]
    end
    self.file_size = image_file.size
  end

  def clean_images
    File.delete(image_save_path) if File.exist?(image_save_path)
    File.delete(thumbnail_save_path) if File.exist?(thumbnail_save_path)
  end

  def compress_image
    File.open(image_save_path) {|f| puts "size before = #{f.size}"}
    image_optim = ImageOptim.new(:pngout => false, :jpegoptim => {:max_quality => 85})
    image_optim.optimize_image!(image_save_path)
    File.open(image_save_path) {|f| puts "size after = #{f.size}"}
  end

  def download_image_from_url(through_proxy)
    puts "Downloading with open-uri : #{source_url}"
    puts Benchmark.measure { 
      opts = {:allow_redirections => :all}
      if through_proxy
        opts[:proxy_http_basic_authentication] = ["http://photo-visualizer.no-ip.org:3128", "photo-visualizer", ENV['SQUID_PASSWORD']]
      end
      open(image_save_path, 'wb') do |file|
        file << open(source_url, opts).read
      end
    }
  end

  def download_image_from_mechanize_page(page_image)
    puts "Downloading with mechanize #{page_image.url.to_s}"
    puts Benchmark.measure { 
      page_image.fetch.save image_save_path #To protect from hotlinking we reuse the same session
    }
  end

  def get_remote_image(page_image, through_proxy)
    if page_image
      download_image_from_mechanize_page(page_image)
    else
      download_image_from_url(through_proxy)
    end
    puts "file size : #{File.open(image_save_path).size}"
  end

  def save_on_S3
    puts "saving on S3"
    puts Benchmark.measure { 
      Facades::S3.new.write_image(key, image_save_path)
      Facades::S3.new.write_thumbnail(key, THUMBNAIL_FORMAT, thumbnail_save_path)
    }
  end

  def download(page_image=nil, through_proxy=false)
    save_ok = false
    rescue_errors do
      get_remote_image(page_image, through_proxy)
      #compress_image #compression can take up to 5min on a t1.micro, and compresses only less than 20% most of the time. disable it for now 
      set_image_info
      generate_thumb
      save_ok = Image.create(website_id, post_id, source_url, key, status, image_hash, width, height, file_size, scrapped_at).present?
      save_on_S3 if save_ok
    end
    
    save_ok
  end

  def rescue_errors
    begin
      yield
    rescue Timeout::Error, Errno::ENOENT => e
      puts e.to_s
    rescue OpenURI::HTTPError => e
      puts "40x error at url : #{source_url}"+e.to_s
    rescue Errno::ECONNRESET => e
      puts e.to_s
    rescue Errno::ETIMEDOUT => e
      puts e.to_s
    rescue EOFError => e
      puts e.to_s
    rescue SocketError => e
      puts e.to_s
    rescue Mechanize::ResponseCodeError => e
      puts e.to_s
    rescue RuntimeError => e
      puts "Runtime error :"+e.to_s
    rescue Zlib::BufError => e
      puts e.to_s
    rescue Net::HTTP::Persistent::Error => e
      puts e.to_s
    rescue Errno::ECONNREFUSED => e
      puts e.to_s
    rescue MiniMagick::Invalid => e
      puts e.to_s
    rescue Errno::ENOMEM => e
      puts e.to_s
    rescue Zlib::DataError => e
      puts e.to_s
    ensure
      clean_images
    end
  end
end
