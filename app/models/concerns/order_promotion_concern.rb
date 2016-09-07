module OrderPromotionConcern
  extend ActiveSupport::Concern
  # This module provides the basic promotions functionality for an order. It
  # handles qualification and application of promotions.
  included do
    has_many :applied_promotions, :foreign_key => 'order_id'
    has_many :promotions, :through => :applied_promotions

    send :attr_accessor, :promo_code
    dump_config :methods => [:promotion_id_dump]
    # attr_accessible(:promotion_id_dump, :promo_code)
  end

  # An error raised if an attempt is made to reapply promotions to an order.
  class PromotionApplyError < StandardError
    def to_s
      "This order has promotions applied to it. Promotions cannot be applied
       more than once"
    end
  end

  # Returns an array of items which have a paid quantity greater than zero.
  # That is, any items which have non-bonus components.
  #
  # @return Array<ActiveRecord::Base>
  # @todo This currently only applies to sku_items
  def candidate_items
    sku_items.select {|i| i.paid_quantity > 0}
  end

  # The promotions that have been applied since the order was last serialised.
  #
  # @return Array<Promotions::Decorator>
  def new_promotions
    @new_promotions ||= []
  end

  # Checks to see if any new promotions have been applied to the order.
  #
  # @return [true, false]
  def new_promotions?
    !new_promotions.empty?
  end

  # Retrieve the promotions that have been applied, but before the order is
  # persisted.
  #
  # @return Array<Promotions::Decorator>
  def pending_promotions
    @pending_promotions ||= []
  end

  # Checks to see if there are any promotions pending/applied to the order.
  #
  # @return [true, false]
  def pending_promotions?
    !pending_promotions.empty?
  end

  # Any promotions that have been previously applied to the order.
  #
  # @return Array<Promotions::Decorator>
  def existing_promotions
    @existing_promotions ||= []
  end

  # Checks for any promotions that have already been applied to the order.
  #
  # @return [true, false]
  def existing_promotions?
    !existing_promotions.empty?
  end

  # Returns the results from checking promotions.
  #
  # @return Promotions::CheckResultCollection
  def promotion_results
    @promotion_results ||= Promotions::CheckResultCollection.new
  end

  # An array of IDs of the promotions that have been applied, used to dump
  # the previous promotion state to session.
  #
  # @return Array<Integer>
  def promotion_id_dump
    pending_promotions.map(&:id)
  end

  # When loading up an order from session, this accessor is used to cache
  # the previous promotion state:
  #
  # @param Array<[String, Numeric]> ids
  # @return Array<Integer>
  def promotion_id_dump=(ids)
    @previous_promotion_ids = ids.map(&:to_i)
  end

  # Returns the IDs of promotions that were previously applied to the order.
  #
  # @return Array<Integer>
  def previous_promotion_ids
    @previous_promotion_ids ||= []
  end

  # Checks to see if there is a code promotion applied to the order and that
  # it is successful.
  #
  # @return [true, false]
  def code_promotion_successful?
    promotion_results.code_based.successful?
  end

  # Checks to see if there is a promotion code set against this order. If it
  # is nil, then code promotions are pending i.e. haven't been checked yet.
  #
  # @return [true, false]
  def code_promotion_unchecked?
    promo_code.blank?
  end

  # Checks to see if a promotion code has been entered, promotions have been
  # applied and that the order has failed to qualify for any code based
  # promotions.
  def code_promotion_failed?
    !promo_code.blank? and promotion_results.code_based.failed?
  end

  # Attempts to apply promotions to this order. It'll return any promotions it
  # successfully applies.
  #
  # @return Array<Promotions::Decorator>
  # @todo Capture result of applying promotions? Probably.
  def apply_promotions!
    raise PromotionApplyError unless pending_promotions.empty?
    @promotion_results = Promotion.active.apply!(self)
    apply_adjustments!

    # Convert all the applied promotions into an array of decorated
    # promotions.
    @pending_promotions = applied_promotions.map {|p| ::Promotions::Decorator.new(p.promotion)}

    # If no promotions have been added to the order, they're all new.
    # Otherwise generate a new collection which is the difference between the
    # existing ones and the new ones.
    if previous_promotion_ids.empty?
      @new_promotions = pending_promotions
    else
      @new_promotions = pending_promotions.reject {|p| previous_promotion_ids.include?(p.id)}
      @existing_promotions = pending_promotions.select {|p| previous_promotion_ids.include?(p.id)}
    end

    pending_promotions
  end
end
