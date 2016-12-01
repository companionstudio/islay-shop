module IslayShop
  class Engine < ::Rails::Engine
    # Set the default provider to Braintree.
    config.payments = ActiveSupport::OrderedOptions.new
    config.payments.provider = :braintree

    config.billable_countries = :all
    config.shippable_countries = ['AU']
    
    config.generators do |g|
      g.test_framework      :rspec,        :fixture => false
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
      g.assets false
      g.helper false
    end
  end
end
