module Promotions
  # Represents the check and/or application of a promotion to an order.
  class CheckResult
    extend Forwardable

    # A whole bunch of methods are delgated to the conditions collection.
    # This a nice shortcut for checking a promotion.
    def_delegators :conditions, :successful?, :partial?, :failed?

    # The promotion this result is related to.
    #
    # @attr_reader Promotion
    attr_reader :promotion

    # The results from checking an order against a promotion's conditions.
    #
    # @attr_reader ConditionResultCollection<PromotionCondition::Result>
    attr_reader :conditions

    # The result of applying a promotion's effects against an order. Will be
    # empty in the case where an order does not qualify.
    #
    # @attr_accessor Array<PromotionEffect::Result>
    attr_accessor :effects

    # Construct a new result with a reference to the promotion.
    #
    # @param Promotion promotion
    # @param Promotions::ConditionResultCollection<PromotionCondition::Result> conditions
    # @param Array<PromotionEffect::Result> effects
    def initialize(promotion, conditions, effects = [])
      @promotion = promotion
      @conditions = conditions
      @effects = effects
    end

    # Checks to see if this result represents an application of effects to an 
    # order.
    #
    # @return [true, false]
    def applied?
      !effects.empty?
    end
  end
end
