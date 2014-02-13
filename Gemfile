source 'https://www.rubygems.org'

gem 'sinatra'
gem 'tilt', '~> 1.4.1'
gem 'tilt-jbuilder', require: 'sinatra/jbuilder'

gem 'endpoint_base', github: 'spree/endpoint_base'
gem 'capistrano'

gem 'netsuite', github: 'huoxito/netsuite', branch: 'patches'

group :development do
  gem "rake"
  gem "pry"
end

group :test do
  gem 'vcr'
  gem 'rspec', '~> 2.14'
  gem 'rack-test'
  gem 'webmock'
end

group :production do
  gem 'foreman'
  gem 'unicorn'
end
