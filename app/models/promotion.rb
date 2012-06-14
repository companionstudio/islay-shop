class Promotion < ActiveRecord::Base
  has_many :orders
  has_many :order_items
  has_many :conditions, :class_name => 'PromotionCondition', :order => 'type ASC'
  has_many :effects,    :class_name => 'PromotionEffect',    :order => 'type ASC'

  attr_accessible :name, :start_at, :end_at, :conditions_attributes, :effects_attributes

  accepts_nested_attributes_for :conditions, :reject_if => :condition_or_effect_inactive?
  accepts_nested_attributes_for :effects,    :reject_if => :condition_or_effect_inactive?

  before_save :clean_conditions_and_effects

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
    cond_types = conditions.map(&:type)
    PromotionCondition.definitions.each do |klass|
      conditions.build(:type => klass.to_s) unless cond_types.include?(klass.to_s)
    end

    effect_types = effects.map(&:type)
    PromotionEffect.definitions.each do |klass|
      effects.build(:type => klass.to_s) unless effect_types.include?(klass.to_s)
    end
  end

  private

  def condition_or_effect_inactive?(param)
    param[:active] == '0'
  end

  def clean_conditions_and_effects
    conditions.each do |condition|
      condition.destroy unless condition.active
    end

    effects.each do |effect|
      effect.destroy unless effect.active
    end
  end
end
