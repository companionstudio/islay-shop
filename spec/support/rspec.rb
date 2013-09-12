module RSpecHelpers
  # A shortcut for constructing a money instance.
  #
  # @param String value
  #
  # @return SpookAndPuff::Money
  def money(value)
    SpookAndPuff::Money.new(value)
  end
end

class ShippingCalculator
  def calculate(order)
    SpookAndPuff::Money.new("15")
  end
end

module RSpecHooks
  def mock_shipping
    before(:all) do
      Order.shipping_calculator = :shipping_calculator
    end

    after(:all) do
      Order.shipping_calculator = :default_shipping_calculator
    end
  end
end

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.include RSpecHelpers
  config.extend  RSpecHooks

  config.mock_with :rspec
  config.fixture_path = "#{Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false
  config.order = "random"
end
