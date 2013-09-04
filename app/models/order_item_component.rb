class OrderItemComponent < ActiveRecord::Base
  extend SpookAndPuff::MoneyAttributes
  attr_money :price, :total
  belongs_to :order_item
  attr_accessible :price, :quantity, :total

  # Checks to see if this component is a bonus.
  #
  # @return [true, false]
  def bonus?
    kind == 'bonus'
  end
end
