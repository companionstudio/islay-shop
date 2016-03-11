class Manufacturer < ActiveRecord::Base
  include Islay::MetaData
  include Islay::Publishable

  extend FriendlyId
  friendly_id :name, :use => :slugged

  include PgSearch
  multisearchable :against => [:name, :description, :metadata]

  attr_accessible :name, :description, :published, :asset_ids
  track_user_edits

  has_many :products
  has_many   :manufacturer_assets
  has_many   :assets,     :through => :manufacturer_assets, :order => 'position ASC'
  has_many   :images,     :through => :manufacturer_assets, :order => 'position ASC', :source => :asset, :class_name => 'ImageAsset'
  has_many   :audio,      :through => :manufacturer_assets, :order => 'position ASC', :source => :asset, :class_name => 'AudioAsset'
  has_many   :videos,     :through => :manufacturer_assets, :order => 'position ASC', :source => :asset, :class_name => 'VideoAsset'
  has_many   :documents,  :through => :manufacturer_assets, :order => 'position ASC', :source => :asset, :class_name => 'DocumentAsset'

  # Generates a relation with additional fields for summarising manufacturers.
  #
  # @return ActiveRecord::Relation
  def self.summary
    select(%{
      published,
      slug,
      name,
      updated_at,
      (SELECT name FROM users WHERE id = updater_id) AS updater_name
    })
  end

  check_for_extensions
end

