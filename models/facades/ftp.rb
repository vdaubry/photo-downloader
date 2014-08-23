require 'net/sftp'

class Ftp
  def upload_file(image)
    unless ENV['TEST']
      begin
        Retriable.retriable :times => 3, :interval => lambda {|attempts| attempts ** 4} do
          Net::SFTP.start(ENV['FTP_ADRESS'], ENV['FTP_LOGIN'], :password => ENV['FTP_PASSWORD']) do |sftp|
            sftp.upload!(image.image_save_path, "#{ENV['IMAGES_PATH']}/#{image.key}")
            sftp.upload!(image.thumbnail_save_path, "#{ENV['THUMBNAILS_PATH']}/#{image.key}")
          end
        end
      rescue Errno::ECONNRESET => e
        puts "Failed to upload image #{image.key} to FTP"+e.to_s
      rescue Net::SSH::Disconnect => e
        puts "Failed to upload image #{image.key} to FTP"+e.to_s
      rescue StandardError => e
        puts "Fail for unknown reason to upload image #{image.key} to FTP : "+e.to_s
        puts "image at path #{image.image_save_path} exist? : #{File.exist? image.image_save_path}"
        puts "image thumbnail at path #{image.thumbnail_save_path} exist? : #{File.exist? image.thumbnail_save_path}"
      end
    end
  end
end