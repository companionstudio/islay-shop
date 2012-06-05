class Promotion < ActiveRecord::Base
  has_many :orders
  has_many :order_items
  has_many :conditions, :class_name => 'PromotionCondition'
  has_many :effects,    :class_name => 'PromotionEffect'
end
