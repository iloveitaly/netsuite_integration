require 'rubygems'
require 'bundler'
require 'pry'

Bundler.require(:default, :test)

require File.join(File.dirname(__FILE__), '..', 'lib/netsuite_integration')
require File.join(File.dirname(__FILE__), '..', 'netsuite_endpoint')

Dir["./spec/support/**/*.rb"].each { |f| require f }

require 'spree/testing_support/controllers'

Sinatra::Base.environment = 'test'

VCR.configure do |c|
  c.allow_http_connections_when_no_cassette = false
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include Spree::TestingSupport::Controllers
end
