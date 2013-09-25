class Promotion < ActiveRecord::Base
  has_many :conditions,               :class_name => 'PromotionCondition', :order => 'type ASC', :dependent => :destroy
  has_many :effects,                  :class_name => 'PromotionEffect',    :order => 'type ASC', :dependent => :destroy
  has_many :applications,             :class_name => 'AppliedPromotion'
  has_many :orders,                   :through => :applications, :order => 'orders.created_at DESC'
  has_many :qualifying_order_items,   :through => :applications
  has_many :bonus_order_items,        :through => :applications

  attr_accessible :name, :start_at, :end_at, :conditions_attributes, :effects_attributes, :active, :description

  accepts_nested_attributes_for :conditions,  :reject_if => :condition_or_order_inactive?
  accepts_nested_attributes_for :effects,     :reject_if => :condition_or_order_inactive?

  track_user_edits
  before_validation :clean_components
  validations_from_schema
  validate :validate_component_compatibility

  # Conditions which are code based. Used in a bunch of predicates defined on
  # Promotion.
  CODE_CONDITIONS = [PromotionCodeCondition, PromotionUniqueCodeCondition].freeze

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
  def self.code_based
    where(%{
      (promotions.start_at IS NULL OR promotions.start_at <= NOW())
      AND (promotions.end_at IS NULL OR promotions.end_at >= NOW())
      AND EXISTS (
        SELECT 1 FROM promotion_conditions AS pcs
        WHERE pcs.promotion_id = promotions.id AND pcs.type IN ('PromotionCodeCondition', 'PromotionUniqueCodeCondition')
      )
    })
  end

  # Generates a relation with some calculated fields.
  #
  # @return ActiveRecord::Relation
  def self.summary
    select(%{
      promotions.*,
      (SELECT name FROM users WHERE users.id = promotions.updater_id) AS updater_name
    })
  end

  # Generates a scope where the promotions are filtered by the provided 
  # argument. Defaults to promotions which are 'current' i.e. upcoming or 
  # running.
  #
  # @param [nil, String] f
  # @return ActiveRecord::Relation
  def self.filtered(f)
    case f
    when 'finished'
      where("promotions.end_at <= NOW()")
    when 'all'
      scoped
    else
      active
    end
  end

  # Generates a scope where the promotions are sorted by the provided argument.
  # It defaults to sorting by updated_at
  #
  # @param [nil, String] f
  # @return ActiveRecord::Relation
  def self.sorted(s)
    if s
      order(s)
    else
      order(:updated_at)
    end
  end

  # The revenue is the total of all billed orders which qualified for the 
  # promotion. Where this attribute doesn't exist, we'll calculate it 
  # ourselves.
  #
  # @return SpookAndPuff::Money
  def revenue
    @revenue ||= begin
      sum = if attributes[:revenue]
        attributes[:revenue]
      else
        orders.where(:status => %w(billed packed complete)).sum(:total)
      end

      SpookAndPuff::Money.new(sum)
    end
  end

  # Predicate which checks to see if the promotion has a condition which relies
  # on codes.
  #
  # @return [true, false]
  def code_based?
    @code_based ||= !(conditions.map(&:class) & CODE_CONDITIONS).empty?
  end

  # Checks to see if the promotion has an application limit specified.
  #
  # @return [true, false]
  def limited?
    !!application_limit
  end

  # A predicate which checks to see if the status of the promotion is 
  # 'running'.
  #
  # @return [true, false]
  def running?
    status == 'running'
  end

  # Calculates the status of the promotion based on the combination of the
  # start date, end date and active option.
  #
  # @return String
  def status
    @status ||= begin
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
  end  

  # Indicates if the promotion has an effect of a particular type
  #
  # @param Symbol name
  # @return Boolean
  def has_effect?(type)
    result = effects.map {|c| c.short_name == type}
    !result.empty? and result.any?
  end

  # Indicates if the promotion has a condition of a particular type
  #
  # @param Symbol name
  # @return Boolean
  def has_condition?(type)
    result = conditions.map {|c| c.short_name == type}
    !result.empty? and result.any?
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
    PromotionCondition.condition_classes.each do |klass|
      conditions.build(:type => klass.to_s) unless cond_types.include?(klass.to_s)
    end

    effect_types = effects.map(&:type)
    PromotionEffect.effect_classes.each do |klass|
      effects.build(:type => klass.to_s) unless effect_types.include?(klass.to_s)
    end

    nil
  end

  private

  # Checks to make sure that the specified conditions and effects are 
  # compatible with each other. It does this by passing each condition/effect
  # pair's scopes to the Scopes module, which maintains lookup hashes etc.
  #
  # It also runs the validations for each component. This is done here rather
  # than through a validates_associated declaration due to the default ordering
  # of validations. We need explicit control.
  #
  # @return nil
  def validate_component_compatibility
    # Run validations against remaining components
    conditions.each(&:valid?)
    effects.each(&:valid?)

    # Check compatibility
    incompatible = false

    conditions.product(effects).each do |c, e|
      if Promotions::Scopes.not_acceptable?(c.condition_scope, e.condition_scope)
        incompatible = true
        e.errors.add(:base, "Not compatible with the '#{c.desc}' condition")
      end
    end

    if incompatible
      errors.add(:base, "The combination of conditions and effects are not compatible")
    end

    nil
  end

  # Ensures any inactive components are deleted from the promotion.
  #
  # @return nil
  def clean_components
    conditions.delete(conditions.reject(&:active))
    effects.delete(effects.reject(&:active))
    nil
  end

  # Run on the accepts_nested_for_* collections. Prevents any stubbed out records
  # that are marked as inactive from even being considered.
  def condition_or_order_inactive?(params)
    params[:active] == '0' and params[:id].blank?
  end
end
