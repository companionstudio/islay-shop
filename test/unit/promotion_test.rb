require 'test_helper'

class PromotionTest < ActiveSupport::TestCase
  test "Quantity condition" do
    promo = Promotion.make!(:quantity_condition)
    qualifying_order = Order.make!
    unqualifying_order = Order.make!


  end
end
