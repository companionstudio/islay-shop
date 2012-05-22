class ProductRange < ActiveRecord::Base
  has_many    :products
  belongs_to  :image, :class_name => 'ImageAsset', :foreign_key => 'asset_id'

  attr_accessible :name, :description

  track_user_edits
end
