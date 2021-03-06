require 'spec_helper'
require_relative '../../models/message_reader'

describe "MessageReader" do

  let(:fake_date) { DateTime.parse("20/10/2010") }
  let(:reader) { MessageReader.new }

  describe "read" do
    it "decode message and downloads image" do
      message = {:website_id => "123", :post_id => "456", :image_url => "http://www.foo.bar/image.png", :scrapped_at => "2010-10-20T00:00:00+00:00"}.to_json
      MessageReader.any_instance.expects(:download_image).with("123", "456", "http://www.foo.bar/image.png", fake_date)
      MessageReader.new(message).read
    end
  end

  describe "download_image" do
    context "url is valid (downloader finds image key)" do
      before(:each) do
        @mock = mock('ImageDownloader')
        @mock.stubs(:key).returns("abc")
        @mock.stubs(:download).returns(nil)
        ImageDownloader.any_instance.stubs(:build_info).returns(@mock)
      end

      it "build new downloader", :local => true do
        ImageDownloader.any_instance.expects(:build_info).with("123", "456", "http://www.foo.bar/image.png", fake_date).returns(@mock)
        reader.download_image("123", "456", "http://www.foo.bar/image.png", fake_date)
      end

      context "url to image", :local => true do
        it "downloads direct image" do
          MessageReader.stubs(:direct_link_to_image?).returns(true)
          @mock.expects(:download).with(nil, false)
          reader.download_image("123", "456", "http://www.foo.bar/image.png", fake_date)
        end
      end

      context "url to host image" do
        it "downloads hosted image" do
          MessageReader.any_instance.stubs(:direct_link_to_image?).returns(false)
          page = mock'Mechanize'
          HostFactory.stub_chain(:create_with_host_url,:page_image).returns(page)
          @mock.expects(:download).with(page)

          reader.download_image("123", "456", "http://www.foo.bar/image.png", fake_date)
        end
      end
    end

    context "url is not valid (downloader image key is nil)" do
      before(:each) do
        @mock = mock('ImageDownloader')
        @mock.stubs(:key).returns(nil)
        ImageDownloader.any_instance.stubs(:build_info).returns(@mock)
      end

      it "downloads image if dowloader key is valid" do
        @mock.expects(:download).never
        reader.download_image("123", "456", "http://www.foo.bar/image.png", fake_date)
      end
    end    
  end

  describe "direct_link_to_image?" do
    context "url to an image" do
      it { reader.direct_link_to_image?("http://www.foo.bar/image.jpg").should == true }
      it { reader.direct_link_to_image?("http://www.foo.bar/image.JPG").should == true }
      it { reader.direct_link_to_image?("http://www.foo.bar/image.jpeg").should == true }
      it { reader.direct_link_to_image?("http://www.foo.bar/image.JPEG").should == true }
      it { reader.direct_link_to_image?("http://www.foo.bar/image.png").should == true }
      it { reader.direct_link_to_image?("http://www.foo.bar/image.PNG").should == true }
      it { reader.direct_link_to_image?("http://www.foo.bar/image.gif").should == true }
      it { reader.direct_link_to_image?("http://www.foo.bar/image.GIF").should == true }
    end
    context "url to an image host" do
      it { reader.direct_link_to_image?("http://www.foo.bar/image/1234").should == false }
      it { reader.direct_link_to_image?("http://www.foo.bar/image.html").should == false }
    end
  end

  describe "require_proxy", :local => true do
    context "url doesn't require proxy" do
      it { reader.require_proxy("http://www.foo.bar/image/1234").should == false }
    end

    context "url requires proxy" do
      it { 
        url = "http://#{YAML.load_file("private-conf/hosts_conf.yml")["hosts_with_proxy"][0]}/image.jpg"
        reader.require_proxy(url).should == true 
      }
    end
  end
end