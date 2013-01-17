class PromotionCondition < ActiveRecord::Base
  include Islay::MetaData
  include IslayShop::PromotionConfig
  include ActionView::Helpers::NumberHelper

  belongs_to :promotion

  CONDITIONS = [
    :all,
    :code,
    :category_quantity,
    :product_quantity,
    :sku_quantity,
    :spend
  ]

  def self.conditions
    @@conditions ||= CONDITIONS.map do |n|
      "Promotion#{n.to_s.classify}Condition".constantize
    end
  end

  def position
    0
  end

  def sku_qualifies?(sku)
    false
  end

  def product_qualifies?(product)
    false
  end

  def category_qualifies?(category, recurse = true)
    false
  end

  def refers_to_sku?(sku)
    false
  end

  def refers_to_product?(product)
    false
  end

  def refers_to_category?(category)
    false
  end

  def specific_to_sku?(sku)
    false
  end

  def specific_to_product?(product)
    false
  end

  def qualifies?(order)
    raise NotImplementedError
  end

  def qualifications(order)
    {}
  end
end
