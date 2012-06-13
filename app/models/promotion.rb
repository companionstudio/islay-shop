class Promotion < ActiveRecord::Base
  has_many :orders
  has_many :order_items
  has_many :conditions, :class_name => 'PromotionCondition'
  has_one  :effect,     :class_name => 'PromotionEffect'

  attr_accessible :name, :start_at, :end_at, :conditions_attributes, :effect_attributes

  accepts_nested_attributes_for :conditions

  def active?
    now = Time.now
    start_at <= now and (end_at.nil? || end_at >= now)
  end

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

  def prefill
    types = conditions.map(&:type)
    PromotionCondition.definitions.each do |klass|
      conditions << klass.new unless types.include?(klass.to_s)
    end
  end
end
