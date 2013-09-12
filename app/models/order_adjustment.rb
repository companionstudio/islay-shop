class OrderAdjustment < ActiveRecord::Base
  extend SpookAndPuff::MoneyAttributes
  attr_money :adjustment
  belongs_to :order
  attr_accessible :source, :adjustment
end
