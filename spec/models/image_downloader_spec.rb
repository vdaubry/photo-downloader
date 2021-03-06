require 'spec_helper'
require 'mechanize'
require_relative '../../models/image_downloader'
require_relative '../../models/facades/s3'

describe ImageDownloader do

	let(:fake_date) { DateTime.parse("20/10/2010") }

	describe "build info" do
		before(:each) do
			@fake_date = DateTime.parse("01/01/2014")
			DateTime.stubs(:now).returns @fake_date
		end

		it "create a new image with parameters" do
			url = "http://foo.bar/1.jpg"
			
			img = ImageDownloader.new.build_info(123, 456, url, fake_date)

			img.website_id.should == 123
			img.post_id.should == 456
			img.source_url.should == url
			img.key.should == @fake_date.to_i.to_s + "_" + "1.jpg"
			img.status.should == ImageDownloader::TO_SORT_STATUS
			img.scrapped_at.should == fake_date.to_s
		end

		it "format special characters" do
			img = ImageDownloader.new.build_info(123, 456, "http://foo.bar/abc-jhvg-emil123.jpg", fake_date)
			img.key.should == @fake_date.to_i.to_s + "_" + "abc_jhvg_emil123.jpg"
		end
    
    it "format accents" do
      img = ImageDownloader.new.build_info(123, 456, "http://foo.bar/abc-zál.jpg", fake_date)
      img.key.should == @fake_date.to_i.to_s + "_" + "abc_zC3A1l.jpg"
    end

		it "sets nil key if invalid uri" do
			img = ImageDownloader.new.build_info(123, 456, "http://foo.*malware*/img.jpg", fake_date)
			img.key.should == nil
		end
	end

	describe "download" do
		let(:image) { ImageDownloader.new("calinours.jpg") }

		before(:each) do
			image.stub_chain(:open, :read) { File.open("spec/ressources/calinours.jpg").read }
			image.stubs(:generate_thumb).returns(true)
			image.stubs(:set_image_info).returns(true)
			image.stubs(:compress_image).returns(true)
		end

		context "without clean tmp images" do
			before(:each) do
				Image.stubs(:create).returns(nil)
				image.stubs(:image_save_path).returns("spec/ressources/tmp/images/calinours.jpg")
				image.stubs(:thumbnail_path).returns("spec/ressources/tmp/images/thumbnails/300/calinours.jpg")
				FileUtils.cp("spec/ressources/calinours.jpg", image.image_save_path)
				FileUtils.cp("spec/ressources/calinours.jpg", image.thumbnail_save_path)
			end

			it "deletes image if API responds with nil" do
				image.expects(:clean_images).once

				image.download.should == false
			end

			it "cleans temporary images" do
				image.download

				File.exist?(image.image_save_path).should == false
				File.exist?(image.thumbnail_save_path).should == false
			end

		end

		context "with clean tmp images" do
			before(:each) do
				image.stubs(:image_save_path).returns("spec/ressources/calinours.jpg")
				image.stubs(:thumbnail_save_path).returns("spec/ressources/thumb/calinours.jpg")
				image.stubs(:clean_images).returns(nil)
			end

			it "uploads file to S3" do
				Facades::S3.any_instance.expects(:write_image)
				Facades::S3.any_instance.expects(:write_thumbnail).twice
				Image.stubs(:create).returns(Image.new({}))
				
				image.download.should == true
			end

			it "POST image to photo downloader" do
				params = {:source_url => "www.foo.bar/image.png", 
					:hosting_url => "www.foo.bar", 
					:key => "543_image.png", 
					:status => "TO_SORT_STATUS", 
					:image_hash => "dfg2345679876", 
					:width => 400, 
					:height => 400, 
					:file_size => 123456, 
					:website_id => 123, 
					:post_id => 456, 
					:scrapped_at => fake_date}
				params.each {|k, v| image.instance_variable_set("@#{k}", v)}
				Image.stubs(:create).with(123, 456, "www.foo.bar/image.png", "543_image.png", "TO_SORT_STATUS", "dfg2345679876", 400, 400, 123456, fake_date).returns(Image.new({}))

				image.download.should == true
			end

			it "ignores file if API create image returns nil" do
				Image.stubs(:create).returns(nil)
				Facades::S3.any_instance.expects(:write_image).never

				image.download.should == false
			end

			context "raises exception" do
				before(:each) do
					image.stubs(:image_save_path).returns("spec/ressources/calinours.jpg")
					@image = ImageDownloader.new("calinours.jpg")
				end

				it "catches timeout error" do
					@image.stubs(:open).raises(Timeout::Error)
					@image.download.should == false
				end

				it "catches 404 error" do
					@image.stubs(:open).raises(OpenURI::HTTPError.new('',mock('io')))
					@image.download.should == false
				end

				it "catches file not found" do
					@image.stubs(:open).raises(Errno::ENOENT)
					@image.download.should == false
				end

				it "catches connection error" do
					@image.stubs(:open).raises(Errno::ECONNRESET)
					@image.download.should == false
				end

				it "catches files error" do
					@image.stubs(:open).raises(EOFError)
					@image.download.should == false
				end

				it "catches socket error" do
					@image.stubs(:open).raises(SocketError)
					@image.download.should == false
				end

				it "catches mechanize responseCodeError" do
					page_image = mock()
					page_image.stubs(:url)
					page_image.stubs(:fetch).raises(Mechanize::ResponseCodeError.new(stub(:code=>404)))
					@image.download(page_image) == false
				end

				it "catches RuntimeEror" do
					@image.stubs(:open).raises(RuntimeError)
					@image.download.should == false
				end

				it "catches Zlib::BufError" do
					@image.stubs(:open).raises(Zlib::BufError)
					@image.download.should == false
				end

				it "catches Net::HTTP::Persistent::Error" do
					@image.stubs(:open).raises(Net::HTTP::Persistent::Error)
					@image.download.should == false
				end

				it "catches MiniMagick::Invalid" do
					@image.stubs(:open).raises(MiniMagick::Invalid)
					@image.download.should == false
				end

				it "catches memory error" do
					@image.stubs(:open).raises(Errno::ENOMEM)
					@image.download.should == false
				end

				it "catches timeout error" do
					@image.stubs(:open).raises(Errno::ETIMEDOUT)
					@image.download.should == false
				end

				it "catches timeout error" do
					@image.stubs(:open).raises(Zlib::DataError)
					@image.download.should == false
				end
			end
		end
	end

	# describe "compress_image" do
	# 	it "compresses image" do
	# 		image = ImageDownloader.new(:key => "large_image.jpg")
	# 		image.stubs(:image_save_path).returns("spec/ressources/large_image.jpg")
	# 		image.compress_image
	# 	end
	# end


	describe "set_image_info" do
		let(:image) { ImageDownloader.new(:key => "calinours.jpg") }

		before(:each) do
			image.stubs(:image_save_path).returns("spec/ressources/calinours.jpg")
		end

		it  {
			image.set_image_info

			image.image_hash.should == "bf5ce4c682bd955f6ebd8b9ea03fe58a"
			image.file_size.should == 70994
			image.width.should == 600
			image.height.should == 390
		}
	end

	describe "generate_thumb" do
		before(:each) do
			@image = ImageDownloader.new("calinours.jpg")
			@image.stubs(:image_save_path).returns("spec/ressources/calinours.jpg")
			@image.stubs(:thumbnail_path).returns("spec/ressources/tmp/images/thumbnails/300/calinours.jpg")

		end

		it "generates a thumbnail" do
			@image.generate_thumb

			File.exist?(@image.thumbnail_save_path).should == true
		end
	end

	describe "key_from_url" do
		before(:each) do
			@fake_date = DateTime.parse("01/01/2014")
			DateTime.stubs(:now).returns @fake_date
		end

		it "turns url of jpg images into key" do
			key = ImageDownloader.new.key_from_url("http://www.somehost.com/9wt2c2wavmv0/0201AP__37_.jpg")
			key.should == "1388534400_0201AP__37_.jpg"
		end

		it "turns url of png images into key" do
			key = ImageDownloader.new.key_from_url("http://www.somehost.com/9wt2c2wavmv0/0201AP__37_.png")
			key.should == "1388534400_0201AP__37_.png"
		end		

		it "removes .html extensions from key" do
			key = ImageDownloader.new.key_from_url("http://www.somehost.com/9wt2c2wavmv0/0201AP__37_.jpg.html")
			key.should == "1388534400_0201AP__37_.jpg"
		end

		it "removes .htm extensions from key" do
			key = ImageDownloader.new.key_from_url("http://www.somehost.com/9wt2c2wavmv0/0201AP__37_.jpg.htm")
			key.should == "1388534400_0201AP__37_.jpg"
		end

		it "adds .jpg extension if no extension" do
			key = ImageDownloader.new.key_from_url("http://www.somehost.com/9wt2c2wavmv0/0201AP__37_.html")
			key.should == "1388534400_0201AP__37_.jpg"
		end
	end
end
