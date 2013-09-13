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

  private

  # A shortcut for generating a result.
  #
  # @param String message
  # @param [OrderItem, Array<OrderItem>] items
  # @return Result
  def result(message, items = [])
    name = self.class.to_s.underscore.match(/^promotion_(.+)_effect$/)[1].to_sym
    Result.new(name, effect_scope, message, [items].flatten)
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

  # Force the subclasses to be loaded
  Dir[File.expand_path('../promotion_*_effect.rb', __FILE__)].each {|f| require f}
end
