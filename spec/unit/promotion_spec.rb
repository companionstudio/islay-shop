require 'spec_helper'

describe Promotion do
  it 'should qualify and apply to order' do
    order = Order.make!
    promotion = Promotion.make!

    promotion.qualifies?(order).should be_true
    promotion.apply!(order)

    # Check to see the order was mutated
  end
end
