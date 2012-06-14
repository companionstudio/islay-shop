class PromotionCondition < ActiveRecord::Base
  include IslayShop::MetaData
  include IslayShop::PromotionConfig

  belongs_to :promotion

  def qualifies?(order)
    raise NotImplementedError
  end

  # Force the subclasses to be loaded
  Dir[File.expand_path('../promotion_*_condition.rb', __FILE__)].each {|f| require f}
end
