module IslayShop
  class Engine < ::Rails::Engine
    config.autoload_paths << File.expand_path("../../app/queries", __FILE__)

    # Set the default provider to Braintree.
    config.payments = ActiveSupport::OrderedOptions.new
    config.payments.provider = :braintree
    
    config.generators do |g|
      g.test_framework      :rspec,        :fixture => false
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
      g.assets false
      g.helper false
    end
  end
end
