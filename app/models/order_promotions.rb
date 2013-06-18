module OrderPromotions
  def self.included(klass)
    
    mattr_accessor :promo_code

    klass.has_many :applied_promotions, :foreign_key => 'order_id'
    klass.has_many :promotions, :through => :applied_promotions

    klass.dump_config :methods => [:promotion_id_dump]

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
  # @return Array<Promotion>
  def apply_promotions!
    raise PromotionApplyError if @promotions_applied

    Promotion.active.each do |p|
      if p.qualifies?(self)
        p.apply!(self)
        unless previous_promotion_ids.include?(p.id)
          new_promotions << p.id
        end
      end
    end

    #apply_adjustments!
    calculate_totals

    @promotions_applied = true

    applied_promotions
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
