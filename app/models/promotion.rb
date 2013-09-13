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

  # Returns a relation scoped to the promotions that have been published and 
  # have current start and end dates.
  #
  # @return ActiveRecord::Relation
  def self.active
    where(%{
      promotions.active = true
      AND (promotions.start_at IS NULL OR promotions.start_at <= NOW())
      AND (promotions.end_at IS NULL OR promotions.end_at >= NOW())
    })
  end

  # Finds all promotions which have a code-based condition.
  #
  # @return Array<Promotion>
  def self.active_code_based
    PromotionQuery.active_code_based
  end

  # Returns a boolean indicating if the promotion is actually running. This 
  # means it has to be both published and have a current start/end date.
  #
  # @return [true, false]
  def active?
    now = Time.now
    active  and start_at <= now and (end_at.nil? || end_at >= now)
  end

  # Calculates the status of the promotion based on the combination of the
  # start date, end date and active option.
  #
  # @return String
  def status
    now = Time.now

    if active
      if    start_at > now  then 'pending'
      elsif end_at > now    then 'running'
      elsif end_at < now    then 'finished'
      end
    else
      if date_range_is_current? then 'paused'
      else 'inactive'
      end
    end
  end

  # The current day of a promotion. This could be a negative value or a value
  # exceeding the total length of the promotion. We don't do bounds checking.
  def current_day
    (Time.now.to_date - start_at.to_date).to_i + 1
  end

  def days_til_start
    if running? or finished?
      0
    else
     (start_at.to_date - Time.now.to_date).to_i
    end
  end

  def total_days
    if open_ended
      "-"
    else
      (end_at.to_date - start_at.to_date).to_i
    end
  end

  def remaining_days
    days = (start_at.to_date - Time.now.to_date).to_i
    days < 0 ? 0 : days
  end

  def remaining_time
    if running?
      from_date = Time.now
    else
      from_date = start_at
    end

    if open_ended
      "(Open ended promotion)"
    elsif (end_at.to_date - from_date.to_date).to_i == 0
      "Ends today"
    elsif (end_at.to_date - from_date.to_date).to_i > 1
      "#{(end_at.to_date - from_date.to_date).to_i} days left"
    elsif (from_date.to_date - Time.now.to_date).to_i == 0
      "Ends today"
    else
      "Ends in #{(from_date.to_date - Time.now.to_date).to_i} days"
    end
  end

  # Indicates if the promotion would be running at the current time based on
  # the start_at and end_at.
  def date_range_is_current?
    now = Time.now
    start_at <= now and (end_at.nil? || end_at >= now)
  end

  # Checks the order against each promotion.
  #
  # This method is designed to be called against a scope 
  # e.g. active.check(order)
  #
  # @param Order order
  # @return Promotions::CheckResultCollection
  def self.check(order)
    Promotions::CheckResultCollection.new(all.map {|p| p.check(order)})
  end

  # Checks the order against each promotion and for each that succeeds, also
  # applies the promotion's effects.
  #
  # This method is designed to be called against a scope 
  # e.g. active.apply(order)
  #
  # @param Order order
  # @return Promotions::CheckResultCollection
  def self.apply!(order)
    Promotions::CheckResultCollection.new(all.map {|p| p.apply!(order)})
  end

  # Checks the order against each promotion condition.
  #
  # @param Order order
  # @return Promotions::CheckResult
  def check(order)
    results = conditions.map {|c| c.check(order)}
    Promotions::CheckResult.new(self, Promotions::ConditionResultCollection.new(results))
  end

  # Applies the promotion's effect to the supplied order.
  #
  # @param Order order
  # @return Promotions::CheckResult
  def apply!(order)
    result = check(order)
    if result.successful?
      order.applied_promotions.build(:promotion => self)
      result.effects = effects.map {|e| e.apply!(order, result.conditions)}
    end

    result
  end

  # When editing a promotion, this method is used to prefill the condition and
  # effect collections. For each type of condition or effect that is missing,
  # we stub out a new record.
  #
  # @return nil
  def prefill
    cond_types = conditions.map(&:type)
    PromotionCondition.subclasses.each do |klass|
      conditions.build(:type => klass.to_s) unless cond_types.include?(klass.to_s)
    end

    effect_types = effects.map(&:type)
    PromotionEffect.subclasses.each do |klass|
      effects.build(:type => klass.to_s) unless effect_types.include?(klass.to_s)
    end

    nil
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
