class PromotionEffect < ActiveRecord::Base
  belongs_to :promotion

  # Force the subclasses to be loaded
  Dir[File.expand_path('../promotion_*_effect.rb', __FILE__)].each {|f| require f}
end
