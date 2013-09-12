class OrderItemAdjustment < ActiveRecord::Base
  extend SpookAndPuff::MoneyAttributes
  attr_money :adjustment, :manual_price
  belongs_to  :order_item

  attr_accessible :kind, :quantity, :adjustment, :source, :manual_price
end
