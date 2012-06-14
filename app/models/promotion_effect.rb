class PromotionEffect < ActiveRecord::Base
  include IslayShop::MetaData
  include IslayShop::PromotionConfig

  belongs_to :promotion

  def apply!(order, conditions)
    raise NotImplementedError
  end

  # Force the subclasses to be loaded
  Dir[File.expand_path('../promotion_*_effect.rb', __FILE__)].each {|f| require f}
end
