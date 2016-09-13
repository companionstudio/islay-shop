class ProductRange < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, :use => [:slugged, :finders]

  include PgSearch
  multisearchable :against => [:name, :description]

  has_many    :products
  belongs_to  :image, :class_name => 'ImageAsset', :foreign_key => 'asset_id'
  track_user_edits
  validations_from_schema

  def self.published
    all
  end
end
