class Product < ActiveRecord::Base
  include IslayShop::MetaData
  include IslayShop::Statuses

  belongs_to :category, :class_name => 'ProductCategory', :foreign_key => 'product_category_id'
  belongs_to :range,    :class_name => 'ProductRange',    :foreign_key => 'product_range_id'
  has_many   :product_assets
  has_many   :assets,   :through => :product_assets
  has_many   :skus, :order => 'position ASC'
  has_many   :sku_assets, :through => :skus, :through => :assets
  has_many   :variants, :class_name => 'ProductVariant', :order => 'position ASC'

  attr_accessible :name, :description, :product_category_id, :product_range_id, :published, :status, :skus_attributes

  track_user_edits
  validations_from_schema

  accepts_nested_attributes_for :skus, :allow_destroy => true, :reject_if => :new_sku?
  validates_associated :skus

  before_save :store_published_at

  def self.newest
    where(:published => true).order('published_at DESC').limit(4)
  end

  def self.published
    where(:published => true).order('name ASC')
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

  def stock_level_status
    'OK'
  end

  def for_sale?
    status == 'for_sale'
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
