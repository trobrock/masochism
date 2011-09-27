$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

ENV["RAILS_ENV"] = "test"

require 'rubygems'
require 'rspec'
require 'rails_app/config/environment'
require 'bundler/setup'


RSpec.configure do |config|
  config.mock_with :mocha
  config.color_enabled = true
end
