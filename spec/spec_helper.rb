# coding: utf-8
ENV["RAILS_ENV"] = "test"
require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require 'rspec/rails'
require 'fakeweb'

Dir[Rails.root.join("../support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  FakeWeb.allow_net_connect = false
  config.before(:all)do
    FakeWeb.clean_registry
  end

  config.include PlatformStubs
end
