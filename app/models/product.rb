class Product < ActiveRecord::Base
  include IslayShop::MetaData
  include IslayShop::Statuses
  include Islay::Publishable
  include Islay::Searchable

  search_terms :against => {:name => 'A'}

  extend FriendlyId
  friendly_id :name, :use => :slugged

  belongs_to :category, :class_name => 'ProductCategory', :foreign_key => 'product_category_id'
  belongs_to :range,    :class_name => 'ProductRange',    :foreign_key => 'product_range_id'
  has_many   :skus, :order => 'position ASC'
  has_many   :sku_assets, :through => :skus, :through => :assets
  has_many   :variants, :class_name => 'ProductVariant', :order => 'position ASC'
  has_many   :stock_logs, :through => :skus, :order => 'created_at DESC'
  has_many   :price_logs, :through => :skus, :order => 'created_at DESC'

  has_many   :product_assets
  has_many   :assets,     :through => :product_assets, :order => 'position ASC'
  has_many   :images,     :through => :product_assets, :order => 'position ASC', :source => :asset, :class_name => 'ImageAsset'
  has_many   :audio,      :through => :product_assets, :order => 'position ASC', :source => :asset, :class_name => 'AudioAsset'
  has_many   :videos,     :through => :product_assets, :order => 'position ASC', :source => :asset, :class_name => 'VideoAsset'
  has_many   :documents,  :through => :product_assets, :order => 'position ASC', :source => :asset, :class_name => 'DocumentAsset'


  attr_accessible :name, :description, :product_category_id, :product_range_id, :published, :status, :skus_attributes, :asset_ids

  track_user_edits
  validations_from_schema

  accepts_nested_attributes_for :skus,    :allow_destroy => true, :reject_if => :new_sku?
  validates_associated :skus

  before_save :store_published_at

  def self.newest
    where(:published => true).order('published_at DESC').limit(4)
  end

  def self.published
    where(:published => true).order('name ASC')
  end

  # Creates a scope where the returned fields are limited and extra calculated
  # fields like a SKU summary have been added.
  def self.summary
    select(%{
      id, slug, published, status, name, updated_at,
      (SELECT name FROM users WHERE id = updater_id) AS updater_name,
      (SELECT ARRAY_TO_STRING(ARRAY_AGG(id::text), ', ')
       FROM skus
       GROUP BY product_id HAVING product_id = products.id) AS skus_summary
    })
  end

  def self.filtered(f)
    if f
      where :published => case f
      when 'published' then true
      when 'unpublished' then false
      end
    else
      scoped
    end
  end

  def self.sorted(s)
    if s
      order(s)
    else
      order(:name)
    end
  end

  # Check to see if any of the SKUs attached to this product are in stock.
  #
  # @return Boolean
  def in_stock?
    skus.map {|s| s.stock_level > 0}.any?
  end

  def stock_warning?
    !in_stock? or stock_low?
  end

  def stock_low?
    false
  end

  def stock_level_status
    if !in_stock?
      'out'
    elsif stock_low?
      'low'
    else
      'ok'
    end
  end

  def friendly_stock_level_status
    'OK'
  end

  def for_sale?
    status == 'for_sale'
  end

  def destroyable?
    true
  end

  # Indicates if the product has it's status set to discontinued.
  #
  # @return Boolean
  def discontinued?
    status == 'discontinued'
  end

  private

  def store_published_at
    if published and published_at.blank?
      self.published_at = Time.now
    end
  end

  def new_sku?(params)
    params.delete(:template) == "true"
  end
end
