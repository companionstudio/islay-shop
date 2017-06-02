class ProductRange < ActiveRecord::Base
  include Islay::MetaData
  include Islay::Publishable
  
  extend FriendlyId
  friendly_id :name, :use => [:slugged, :finders]

  include PgSearch
  multisearchable :against => [:name, :description]

  has_many    :products
  belongs_to  :image, :class_name => 'ImageAsset', :foreign_key => 'asset_id'
  track_user_edits
  validations_from_schema

  def self.published
    where(published: true)
  end

  def self.latest
    order('published_at DESC').limit(1).last
  end

end
