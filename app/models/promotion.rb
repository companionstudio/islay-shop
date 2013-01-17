class Promotion < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, :use => :slugged

  class_attribute :lockable_attr_accessible

  has_many :conditions,               :class_name => 'PromotionCondition', :order => 'type ASC'
  has_many :effects,                  :class_name => 'PromotionEffect',    :order => 'type ASC'
  has_many :applications,             :class_name => 'AppliedPromotion'
  has_many :qualifying_order_items,   :through => :applications
  has_many :bonus_order_items,        :through => :applications

  has_many :orders,
           :counter_sql => proc {%{SELECT COUNT(orders.*) FROM orders WHERE EXISTS (SELECT 1 FROM applied_promotions AS ap WHERE ap.order_id = orders.id AND ap.promotion_id = #{id})}},
           :finder_sql  => proc {%{SELECT orders.* FROM orders WHERE EXISTS (SELECT 1 FROM applied_promotions AS ap WHERE ap.order_id = orders.id AND ap.promotion_id = #{id}) ORDER BY created_at}}

  has_many :order_summaries,
           :counter_sql => proc {%{SELECT COUNT(order_summaries.*) FROM order_summaries WHERE EXISTS (SELECT 1 FROM applied_promotions AS ap WHERE ap.order_id = order_summaries.id AND ap.promotion_id = #{id})}},
           :finder_sql  => proc {%{SELECT order_summaries.* FROM order_summaries WHERE EXISTS (SELECT 1 FROM applied_promotions AS ap WHERE ap.order_id = order_summaries.id AND ap.promotion_id = #{id}) ORDER BY created_at}}


  belongs_to  :image,           :class_name => 'ImageAsset', :foreign_key => 'image_asset_id'

  attr_accessible :name, :end_at, :active, :description, :simple_end_at, :image_asset_id

  # This attribute is used to specify attributes which will not be available
  # if the promotion is locked. See the #locked? method for example.
  self.lockable_attr_accessible = [:start_at, :conditions_attributes, :effects_attributes, :simple_start_at]

  accepts_nested_attributes_for :conditions,  :reject_if => :condition_or_order_inactive?
  accepts_nested_attributes_for :effects,     :reject_if => :condition_or_order_inactive?

  before_validation :clean_conditions_and_effects
  before_destroy    :protect_if_applied

  validates_associated :conditions, :effects

  validates :name,        :presence => true, :length => {:minimum => 1, :maximum => 200}
  validates :description, :length => {:maximum => 4000}
  validate  :validate_start_and_end_dates


  # Returns a lookup class for caching active promotions
  #
  # @return Promotion::Lookup
  def self.lookup
    promotions = advertised.all
    Lookup.new(promotions)
  end

  # A cache for active promotions to allow them to be queried efficiently
  class Lookup

    # Creates an instance of the lookup class and stores the promotions collection
    #
    # @param Array<Promotion>
    def initialize(promotions)
      @promotions = promotions
    end

    # Returns any active promotions that apply to a particular SKU.
    #
    # @param Sku sku
    #
    # @return [Array<Promotion>, Array]
    def for_sku(sku)
      @promotions.select {|p| p.specific_to_sku?(sku)}
    end

    # Returns any active promotions that apply to a particular product.
    #
    # @param Product product
    #
    # @return [Array<Promotion>, Array]
    def for_product(product)
      @promotions.select {|p| p.specific_to_product?(product)}
    end

    def refers_to_product(product)
      @promotions.select {|p| p.product_qualifies?(product, true)}
    end

    # Returns any active promotions that apply to a particular product category.
    #
    # @param Category category
    # @param Boolean recurse If true, recurse up through the parents, looking for qualifying categories.
    #
    # @return [Array<Promotion>, Array]
    def for_category(category, recurse = true)
      @promotions.select {|p| p.category_qualifies?(category, recurse)}
    end


    # Returns any active promotions that are member exclusive
    #
    # @return [Array<Promotion>, Array]
    def for_members
      @promotions.select {|p| p.member_exclusive?}
    end

  end

  # Returns the promotions that have been published and have current start and
  # end dates
  def self.active
    where %{
      active = true
      AND (start_at IS NULL OR start_at <= NOW())
      AND (end_at IS NULL OR end_at >= NOW())
    }
  end

  def self.starts_within(days = 7)
    where %{
      active = true
      AND (start_at::date > NOW())
      AND (start_at::date < NOW() + interval '#{days} days')
    }
  end

  #Advertised excludes code-based promotions, so we don't show them on the site
  def self.advertised
    active.where %{
      NOT EXISTS (
        SELECT 1 FROM promotion_conditions AS pcs
        WHERE pcs.promotion_id = promotions.id AND pcs.type = 'PromotionCodeCondition'
      )
    }
  end

  # Returns any active promotions that apply to a particular SKU.
  def self.for_sku(sku)
    active.select {|s| p.sku_qualifies?(sku)}
  end

  # Returns any active promotions that apply to a particular product.
  def self.for_product(product)
    active.select {|p| p.product_qualifies?(product)}
  end

  def self.refers_to_product(product)
    active.select {|p| p.product_qualifies?(product, true)}
  end

  # Returns any active promotions that apply to a particular product category.
  def self.for_category(category, recurse = true)
    active.select {|p| p.category_qualifies?(category, recurse)}
  end

  # Returns the active promotions which have a membership as part of the set of
  # conditions.
  #
  # @return [Promotion]
  def self.for_members
    active.where %{
      EXISTS (
        SELECT 1 FROM promotion_conditions AS pcs
        WHERE pcs.promotion_id = promotions.id AND pcs.type = 'PromotionMembershipCondition'
      )
    }
  end

  # Returns the active promotions which have a code as part of the set of
  # conditions.
  #
  # @param code an optional code to check and limit results
  #
  # @return [Promotion]
  def self.active_with_code(code = nil)
    if code
      active.where %{
        EXISTS (
          SELECT 1 FROM promotion_conditions AS pcs
          WHERE pcs.promotion_id = promotions.id AND pcs.type = 'PromotionCodeCondition' AND 'code=>#{code}'::hstore <@ config
        )
      }
    else
      active.where %{
        EXISTS (
          SELECT 1 FROM promotion_conditions AS pcs
          WHERE pcs.promotion_id = promotions.id AND pcs.type = 'PromotionCodeCondition'
        )
      }
    end
  end

  def self.with_status(status = 'all')
    case status
    when 'running' then
      where %{
        active = true
        AND (start_at::date < NOW())
        AND (end_at::date > NOW() OR end_at IS NULL)
      }
    when 'finished' then
      where %{
        end_at::date < NOW()
      }
    when 'pending' then
      where %{
        start_at::date > NOW()
      }
    when 'paused' then
      where %{
        active = false
        AND (start_at::date < NOW())
        AND (end_at::date > NOW() OR end_at IS NULL)
      }
    else
      all
    end
  end

  # Checks to see if there any active promotions using a code based condition.
  #
  # @return Boolean
  def self.active_with_code?
    active_with_code.exists?
  end

  # A formatted date string
  #
  # @return String
  def simple_start_at
    format_date_output(:start_at)
  end

  # A formatted date string
  #
  # @return String
  def simple_end_at
    format_date_output(:end_at)
  end

  # Accepts a formatted date string and assigns it to the start_at attribute.
  #
  # @param String input
  #
  # @return Time
  def simple_start_at=(input)
    format_date_input(:start_at, input)
  end

  # Accepts a formatted date string and assigns it to the end_at attribute.
  #
  # @param String input
  #
  # @return Time
  def simple_end_at=(d)
    format_date_input(:end_at, d)
  end

  # Indicates if the promotion has an effect of a particular type
  #
  # @param string type
  #
  # @return Boolean
  def has_effect?(type)
    effects.map {|e| e.is_a?(type)}.any?
  end

  # Indicates if the promotion has a condition of a particular type
  #
  # @param string type
  #
  # @return Boolean
  def has_condition?(type)
    conditions.map {|c| c.is_a?(type)}.any?
  end

  # Return a Effect of a particular type
  #
  # @param string type
  #
  # @return Effect
  def effect(type)
    effects.find {|e| e.is_a?(type)}
  end

  # Return a condition of a particular type
  #
  # @param string type
  #
  # @return Condition
  def condition(type)
    conditions.find {|c| c.is_a?(type)}
  end

  # This is used to indicate if a promotion involves the specified SKU in some
  # way. Recurse = true also considers promotions at the product and category level.
  def sku_qualifies?(sku, recurse = true)
    if sku.is_a?(String) or sku.is_a?(Integer)
      sku = Sku.find(sku)
    end
    conditions.map {|c| c.sku_qualifies?(sku)}.any?
  end

  def specific_to_sku?(sku)
    if sku.is_a?(String) or sku.is_a?(Integer)
      sku = Sku.find(sku)
    end
    conditions.map do |c|
      c.specific_to_sku?(sku)
    end.any?
  end

  # This is used to indicate if a promotion involves the specified sku in
  # some way. Recurse = true also considers promotions at the category level.
  def product_qualifies?(product, recurse = true)
    if product.is_a?(String) or product.is_a?(Integer)
      product = Product.find(product)
    end
    qualifiers = conditions.map do |c|
      if recurse
        c.product_qualifies?(product)
      else
        c.refers_to_product?(product)
      end
    end
    qualifiers.any?
  end

  def specific_to_product?(product)
    if product.is_a?(String) or product.is_a?(Integer)
      product = Product.find(product)
    end
    conditions.map do |c|
      c.specific_to_product?(product)
    end.any?
  end

  # This is used to indicate if a promotion involves the specified product
  # category in some way.
  def category_qualifies?(category, recurse = true)
    if category.is_a?(String) or category.is_a?(Integer)
      category = ProductCategory.find(category)
    end
    conditions.map {|c| c.category_qualifies?(category, recurse)}.any?
  end

  # Indicates if the promotion has any effects which provide the specified SKU
  # as an award.
  #
  # @param Sku sku
  #
  # @return Boolean
  def reward_sku?(sku)
    effects.map {|e| e.reward_sku?(sku)}.any?
  end

  # Indicates if the promotion has any effects which provide the specified
  # product as an award.
  #
  # @param Product product
  #
  # @return Boolean
  def reward_product?(product)
    effects.map {|e| e.reward_product?(product)}.any?
  end

  # Indicates if the promotion has any effects which provide a product as a reward
  #
  # @return Boolean
  def reward_any_product?
    effects.map {|e| e.reward_any_product?(product)}.any?
  end

  def member_exclusive?
    has_condition? PromotionMembershipCondition
  end

  def pending?
    start_at > Time.now
  end

  attr_accessor :open_ended
  def open_ended?
    end_at.blank?
  end

  def open_ended
    end_at.blank?
  end

  def open_ended=(switch)
    end_at = nil if switch
  end

  # Returns a boolean indicating if the promotion is actually running. This means
  # it has to be both published and have a current start/end date.
  def running?
    start_at <= Time.now and !finished?
  end

  # Indicates if the promotion's end_at date is in the past.
  def finished?
    !open_ended && end_at < Time.now
  end

  # Calculates the status of the promotion based on the combination of the
  # start date, end date and active option.

  attr_reader :status
  def status
    now = Time.now

    if active
      if    start_at > now  then 'pending'
      elsif open_ended      then 'running'
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
    q = conditions.map {|c|
      c.qualifies?(order)
    }
    q.all?
  end

  # Return the conditions for the promotions, and whether they passed or failed qualification.
  #
  # @return array<Condition, Boolean>
  def qualifications(order)
    conditions.map {|c| [c, c.qualifies?(order)]}
  end

  # This returns a hash keyed by sku_id and values indicating the number of times
  # a SKU has qualified for the conditions.
  #
  # This is used by some of the effects to calculate bonuses e.g. buy one get
  # one free needs to know how many skus qualify.
  def sku_qualifications(order)
    @qualifications ||= conditions.inject({}) do |h, c|
      h.merge!(c.qualifications(order))
      h
    end
  end

  # Applies each of the effects to the order, then assigns this promotion to
  # the order via the PromotionOrder model.
  def apply!(order)
    effects.each do |e|
      if sku_qualifications(order).empty?
        e.apply!(order, order) #If no sku-level qualifications apply, we say that the whole order 'qualifies'
      else
        e.apply!(order, sku_qualifications(order))
      end
    end
  end

  # When editing a promotion, this method is used to prefill the condition and
  # effect collections. For each type of condition or effect that is missing,
  # we stub out a new record.
  def prefill
    cond_types = conditions.map(&:class)
    PromotionCondition.conditions.each do |klass|
      conditions.build(:type => klass.to_s) unless cond_types.include?(klass)
    end

    conditions.sort_by! do |c|
      c.position
    end

    effect_types = effects.map(&:class)
    PromotionEffect.effects.each do |klass|
      effects.build(:type => klass.to_s) unless effect_types.include?(klass)
    end
  end

  # Checks to see if portions of the promotion should be guarded from updates.
  # The basic rule is that any promotion that has had orders placed against it
  # are locked.
  #
  # @return Boolean
  def locked?
    !destroyable?
  end

  # Indicates if this promotion can be destroyed. The basic rule is that if the
  # promotion has any orders against it, destruction is a no no.
  #
  # @return Boolean

  def destroyable?
    applications.empty?
  end

  #Look at the effects and conditions, and group the promotion
  def classification

    classification_name = ""

    classification_name << case conditions.count
    when 0 then
      'no_condition'
    when 1 then

      case conditions[0]
        when PromotionSkuQuantityCondition, PromotionProductQuantityCondition, PromotionCategoryQuantityCondition
          'buy_n'
        when PromotionMembershipCondition then 'members'
        when PromotionSpendCondition then 'spend_x'
        else conditions[0].type.underscore
      end
    else
      'multi_condition'
    end

    classification_name << case effects.count
    when 0 then
      '_no_effect'
    when 1 then
      case effects[0]
      when PromotionGetNFreeEffect then '_get_n_free'
      when PromotionBonusEffect then '_bonus'
      when PromotionShippingEffect then '_shipping'
      else '_' + effects[0].type.underscore
      end
    else
      '_multi_effect'
    end

    classification_name
  end

  def description_html
    render_markdown(description)
  end

  #Return the sum total of all the orders placed by members who joined at this event.
  def revenue
    order_summaries.reduce(0){|a, o|a + o.total}
  end

  private

  # This overrides a method in Rails. This is a method for dynamically setting
  # which attributes are accessible. In this case we use the #locked? method
  # to determine if certain attrs should be removed from the white-list.
  #
  # @return Array<Symbol>
  def mass_assignment_authorizer(role = nil)
    if locked?
      super
    else
      super + lockable_attr_accessible
    end
  end

  # Accepts a model date attribute and turns it into a formatted string.
  #
  # @param Symbol attr
  #
  # @return String
  def format_date_output(attr)
    self[attr] ? self[attr].strftime('%d/%m/%Y') : nil
  end

  # Accepts a symbol indicating a date attribute and a formatted date string.
  # It converts the date into a local time and assigns it to the attribute.
  #
  # @param Symbol attr
  # @param String input
  #
  # @return Time
  def format_date_input(attr, input)
    self[attr] = Time.zone.parse(input)
  end

  # Prevent destruction of a promotion if it's been applied to any orders.
  def protect_if_applied
    raise ActiveRecord::ReadOnlyRecord unless destroyable?
  end

  # Checks that the start date is before the end date and that the end date is
  # in the future.
  def validate_start_and_end_dates
    unless start_at
      errors.add(:start_at, 'can\'t be blank')
    end
    unless open_ended
      if start_at >= end_at
        errors.add(:start_at, 'must be earlier than the end date')
      end

      if end_at < -1.day.ago
        errors.add(:end_at, 'must be today or later')
      end
    end
  end

  # Run on the accepts_nested_for_* collections. Prevents any stubbed out records
  # that are marked as inactive from even being considered.
  def condition_or_order_inactive?(params)
    params[:active] == '0' and params[:id].blank?
  end

  # Reject any conditions or effects that have not been marked as inactive. This
  # will remove existing records and omit any new/stubbed records.
  def clean_conditions_and_effects
    conditions.each do |condition|
      conditions.destroy(condition) unless condition.active
    end

    effects.each do |effect|
      effects.destroy(effect) unless effect.active
    end
  end
end
