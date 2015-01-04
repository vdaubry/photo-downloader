source 'https://rubygems.org'

gem 'dotenv',                   '~> 1.0.2'
gem 'activemodel',              '~> 4.1.7'
gem 'activesupport',            '~> 4.1.7'
gem 'sentry-raven',             '~> 0.10.1'
gem 'aws-sdk',                  '~> 1.57.0'
gem 'open_uri_redirections',    '~> 0.1.4'
gem 'fastimage',                '~> 1.6.4'
gem 'mini_magick',              '~> 3.8.1'
gem 'progressbar',              '~> 0.21.0'
gem 'image_optim',              '~> 0.18.0'
gem 'retriable',                '~> 1.4.1'
gem 'mail',                     git: 'git://github.com/pwnall/mail', :ref => 'd367c0827b10161d7cc42fd22237daa9a7cedafd' #Fixes mail dependency with mimetypes 1.x which conflicts with Mechanize dependency on mimetypes 2.x => https://github.com/mikel/mail/issues/641
gem 'mechanize',                '~> 2.7.3'
gem 'httparty',                 '~> 0.13.1'

group :test do
  gem 'coveralls',              '~> 0.7.1', require: false
  gem 'rspec',                  '~> 3.1.0'
  gem 'factory_girl',           '~> 4.5.0'
  gem 'mocha',                  '~> 1.1.0'
  gem 'webmock',                '~> 1.20.2'
  gem 'vcr',                    '~> 2.9.3'
end

group :development do
  gem 'spring-commands-rspec',  '~> 1.0.2'
  gem 'byebug',                 '~> 3.5.1'
end