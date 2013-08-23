module IslayShop
  class Engine < ::Rails::Engine
    config.autoload_paths << File.expand_path("../../app/queries", __FILE__)

    # Set the default provider to Braintree.
    config.payments = ActiveSupport::OrderedOptions.new
    config.payments.provider = :braintree
  end
end
