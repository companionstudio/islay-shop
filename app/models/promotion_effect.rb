class PromotionEffect < ActiveRecord::Base
  include Islay::MetaData
  include IslayShop::PromotionConfig

  has_many    :applications,            :class_name => 'AppliedPromotion'
  has_many    :orders,                  :through => :applications
  has_many    :qualifying_order_items,  :through => :applications
  has_many    :bonus_order_items,       :through => :applications

  belongs_to  :promotion

  EFFECTS = [
    :competition_entry,
    :bonus,
    :discount,
    :get_n_free,
    :shipping
  ]

  def self.effects
    @@effects ||= EFFECTS.map do |n|
      "Promotion#{n.to_s.classify}Effect".constantize
    end
  end

  # Indicates if the specified SKU is a reward in an effect.
  #
  # @param Sku sku
  #
  # @return Boolean
  def reward_sku?(sku)
    false
  end

  # Indicates if the specified product is a reward in an effect.
  #
  # @param Product product
  #
  # @return Boolean
  def reward_product?(product)
    false
  end

  # Indicates if the effect provides a product or sku as an award
  #
  # @return Boolean
  def reward_any_product?
    false
  end

  def reward_product
    []
  end

  def apply!(order, qualifications)
    raise NotImplementedError
  end

  def required_stock
    {}
  end
end
