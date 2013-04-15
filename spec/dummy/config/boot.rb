require 'rubygems'
gemfile = File.expand_path('../../../../Gemfile', __FILE__)

if File.exist?(gemfile)
  # Set up gems listed in the Gemfile.
  ENV['BUNDLE_GEMFILE'] ||= gemfile
  require 'bundler/setup'
end

$:.unshift File.expand_path('../../../../lib', __FILE__)