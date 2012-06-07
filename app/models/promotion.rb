class Promotion < ActiveRecord::Base
  has_many :orders
  has_many :order_items
  has_many :conditions, :class_name => 'PromotionCondition'
  has_one  :effect,     :class_name => 'PromotionEffect'

  # Derives a description of the promotion by looking at the conditions and the
  # effect.
  def summary

  end

  def qualifies?(order)
    conditions.map {|c| c.qualifies?(order)}.all?
  end

  def apply!(order)
    effect.apply!(order)
  end
end
