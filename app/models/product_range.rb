class ProductRange < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, :use => :slugged

  include PgSearch
  multisearchable :against => [:name, :description]

  has_many    :products
  belongs_to  :image, :class_name => 'ImageAsset', :foreign_key => 'asset_id'
  attr_accessible :name, :description
  track_user_edits

  def self.published
    all
  end
end
