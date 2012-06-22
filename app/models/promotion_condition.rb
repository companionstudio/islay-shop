class PromotionCondition < ActiveRecord::Base
  include IslayShop::MetaData
  include IslayShop::PromotionConfig

  belongs_to :promotion

  def sku_qualifies?(sku)
    false
  end

  def product_qualifies?(product)
    false
  end

  def category_qualifies?(category)
    false
  end

  def qualifies?(order)
    raise NotImplementedError
  end

  def qualifications(order)
    {}
  end

  # Force the subclasses to be loaded
  Dir[File.expand_path('../promotion_*_condition.rb', __FILE__)].each {|f| require f}
end
