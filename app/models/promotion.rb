class Promotion < ActiveRecord::Base
  has_many :conditions,               :class_name => 'PromotionCondition', :order => 'type ASC'
  has_many :effects,                  :class_name => 'PromotionEffect',    :order => 'type ASC'
  has_many :applications,             :class_name => 'AppliedPromotions'
  has_many :orders,                   :through => :applications
  has_many :qualifying_order_items,   :through => :applications
  has_many :bonus_order_items,        :through => :applications

  attr_accessible :name, :start_at, :end_at, :conditions_attributes, :effects_attributes, :active, :description

  accepts_nested_attributes_for :conditions,  :reject_if => :condition_or_order_inactive?
  accepts_nested_attributes_for :effects,     :reject_if => :condition_or_order_inactive?

  before_validation :clean_conditions_and_effects

  validations_from_schema
  validates_associated :conditions, :effects

  # Returns the promotions that have been published and have current start and
  # end dates
  def self.active
    PromotionQuery.active
  end

  # Returns any active promotions that apply to a particular SKU.
  def self.for_sku(sku)
    active.select {|p| p.product_qualifies?(sku)}
  end

  # Returns any active promotions that apply to a particular product.
  def self.for_product(product)
    active.select {|p| p.product_qualifies?(product)}
  end

  # Returns any active promotions that apply to a particular product category.
  def self.for_category(category)
    active.select {|p| p.category_qualifies?(category)}
  end

  # This is used to indicate if a promotion involves the specified SKU in some
  # way.
  def sku_qualifies?(sku)
    conditions.map {|c| c.sku_qualifies?(sku)}.any?
  end

  # This is used to indicate if a promotion involves the specified product in
  # some way.
  def product_qualifies?(product)
    conditions.map {|c| c.product_qualifies?(product)}.any?
  end

  # This is used to indicate if a promotion involves the specified product
  # category in some way.
  def category_qualifies?(category)
    conditions.map {|c| c.category_qualifies?(category)}.any?
  end

  # Returns a boolean indicating if the promotion is actually running. This means
  # it has to be both published and have a current start/end date.
  def active?
    now = Time.now
    active  and start_at <= now and (end_at.nil? || end_at >= now)
  end

  # Derives a description of the promotion by looking at the conditions and the
  # effect.
  #
  # TODO:
  def summary

  end

  # Returns a hash keyed by sku_id, with values indicating the amount of stock
  # required in order fulfill the effects of a promotion.
  #
  # In some cases, this will return an empty hash e.g. for free shipping or
  # order total discounts.
  #
  # TODO:
  def required_stock

  end

  # Queries each condition attached to the promotion, and returns a boolean
  # indicating the qualification of the specified order.
  #
  # The conditions are ANDed together. All or nothing.
  def qualifies?(order)
    conditions.map {|c| c.qualifies?(order)}.all?
  end

  # This returns a hash keyed by sku_id and values indicating the number of times
  # a SKU has qualified for the conditions.
  #
  # This is used by some of the effects to calculate bonuses e.g. buy one get
  # one free needs to know how many skus qualify.
  def qualifications(order)
    @qualifications ||= conditions.inject({}) do |h, c|
      h.merge!(c.qualifications(order))
      h
    end
  end

  # Applies each of the effects to the order, then assigns this promotion to
  # the order via the PromotionOrder model.
  def apply!(order)
    effects.each {|e| e.apply!(order, qualifications(order))}
  end

  # When editing a promotion, this method is used to prefill the condition and
  # effect collections. For each type of condition or effect that is missing,
  # we stub out a new record.
  def prefill
    cond_types = conditions.map(&:type)
    PromotionCondition.subclasses.each do |klass|
      conditions.build(:type => klass.to_s) unless cond_types.include?(klass.to_s)
    end

    effect_types = effects.map(&:type)
    PromotionEffect.subclasses.each do |klass|
      effects.build(:type => klass.to_s) unless effect_types.include?(klass.to_s)
    end
  end

  private

  # Run on the accepts_nested_for_* collections. Prevents any stubbed out records
  # that are marked as inactive from even being considered.
  def condition_or_order_inactive?(params)
    params[:active] == '0' and params[:id].blank?
  end

  # Reject any conditions or effects that have not been marked as inactive. This
  # will remove existing records and omit any new/stubbed records.
  def clean_conditions_and_effects
    conditions.each do |condition|
      conditions.delete(condition) unless condition.active
    end

    effects.each do |effect|
      effects.delete(effect) unless effect.active
    end
  end
end
