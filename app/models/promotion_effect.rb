class PromotionEffect < ActiveRecord::Base
  include Islay::MetaData
  include Promotions::Config

  has_many    :applications,            :class_name => 'AppliedPromotion'
  has_many    :orders,                  :through => :applications
  has_many    :qualifying_order_items,  :through => :applications
  has_many    :bonus_order_items,       :through => :applications

  belongs_to  :promotion

  # Applies the effect to the provided order. It may also optionally use the
  # condition results passed in as the second arg.
  #
  # @param Order order
  # @param Promotion::ConditionResultCollection
  # @return PromotionEffect::Result
  def apply!(order, results)
    raise NotImplementedError
  end

  # Generates a nice symbol representing the name of the effect based on the
  # class name e.g. PromotionBonusEffect becomes :bonus
  #
  # @return Symbol
  def self.short_name
    self.name.underscore.match(/^promotion_(.+)_effect$/)[1].to_sym
  end

  # Loads effect subclasses by looking for files on disk and kicking off Rails'
  # constant_missing magic by extracting the class name from the file name.
  #
  # Bloody horrible really, but the only way to get the subclasses reliably.
  #
  # @return Array<PromotionEffect>
  def self.effect_classes
    @@effect_classes ||= Dir[File.expand_path('../promotion_*_effect.rb', __FILE__)].map do |f|
      f.match(/(promotion_[a-z_]+_effect)/)[1].classify.constantize
    end
  end

  # Generates a symbol representing the type of condition.
  #
  # @return Symbol
  def short_name
    @short_name ||= self.class.to_s.underscore.match(/^promotion_(.+)_effect$/)[1].to_sym
  end

  private

  # A shortcut for generating a result.
  #
  # @param String message
  # @param [OrderItem, Array<OrderItem>] items
  # @return Result
  def result(message, items = [])
    Result.new(self.class.short_name, effect_scope, message, [items].flatten)
  end

  # Represents the result of applying the effect to an order.
  class Result
    attr_reader :scope

    # Name of the effect, derived from it's class name
    #
    # @attr_reader Symbol
    attr_reader :effect

    # Human readable message
    attr_reader :message

    # The order items affected. May be empty.
    #
    # @attr_reader Array<OrderItem>
    attr_reader :items

    def initialize(effect, scope, message, items = [])
      @effect   = effect
      @scope    = scope
      @message  = message
      @items    = items
    end
  end
end
