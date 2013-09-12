class Order
  # This module provides the basic promotions functionality for an order. It 
  # handles qualification and application of promotions.
  module Promotions
    def self.included(klass)
      klass.has_many :applied_promotions, :foreign_key => 'order_id'
      klass.has_many :promotions, :through => :applied_promotions
      klass.send :attr_accessor, :promo_code
      klass.dump_config :methods => [:promotion_id_dump]
      klass.attr_accessible(:promotion_id_dump, :promo_code)

      klass
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
    #
    # @todo This currently only applies to sku_items
    def candidate_items
      sku_items.select {|i| i.paid_quantity > 0}
    end

    # Attempts to apply promotions to this order. It'll return any promotions it
    # successfully applies.
    #
    # @return Promotion::PromotionResultCollection
    # @todo Capture result of applying promotions? Probably.
    def apply_promotions!
      raise PromotionApplyError if @promotions_applied
      results = Promotion.active.apply!(self)
      apply_adjustments!
      @promotions_applied = true
      results
    end

    # The promotions that have been applied since the order was last serialised
    #
    # @return Array<Promotions, nil>
    def new_promotions
      @new_promotions ||= [] 
    end

    def new_promotions?
      !new_promotions.empty?
    end

    # Retrieve the promotions that have been applied, but before the order is persisted:
    #
    # @return Array<Promotion>
    def pending_promotions
      if @promotions_applied == true
        applied_promotions.map(&:promotion).uniq
      else
        []
      end
    end

    # An array of IDs of the promotions that have been applied, used to dump the previous promotion state to session.
    #
    # @return Array Promotion IDs
    def promotion_id_dump
      applied_promotions.map{|ap| ap.promotion.id}
    end

    # When loading up an order from session, this accessor is used to cache the previous promotion state:
    #
    # @param [Array<Number>] ID's of promotions
    def promotion_id_dump=(ids)
      @previous_promotion_ids = ids
    end

    def previous_promotion_ids
      @previous_promotion_ids ||= []
    end
  end
end
