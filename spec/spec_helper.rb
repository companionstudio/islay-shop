ENV["RAILS_ENV"] ||= 'test'

require 'islay'
require 'islay_shop'
require File.expand_path("../dummy/config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/mocks'
require 'factory_girl_rails'

RSpec.configure do |config|
  config.mock_with :rspec
  config.use_transactional_fixtures = true
  config.infer_base_class_for_anonymous_controllers = false
  config.order = "random"
end
