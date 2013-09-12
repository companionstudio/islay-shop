ENV['RAILS_ENV'] ||= 'test'
require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require 'debugger'
require 'vcr'
require 'webmock'
require 'factory_girl_rails'
require 'ffaker'
require 'rspec/rails'
require 'rspec/mocks'

Dir["./spec/support/*.rb"].each {|f| require f}

# Fake a current user so as to make the user tracking magic just work
Thread.current[:current_user] = User.first || FactoryGirl.create(:user)
