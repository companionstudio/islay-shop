class Offer < ActiveRecord::Base
  validations_from_schema
  include Islay::MetaData

  include OfferOrdersConcern

  include PgSearch
  multisearchable :against => [:name]

  extend FriendlyId
  friendly_id :name, :use => [:slugged, :finders]

  extend SpookAndPuff::MoneyAttributes
  attr_money :price

  has_many :offer_items, :autosave => true
  has_many :skus, through: :offer_items
  has_many :products, through: :skus

  has_many :offer_orders
  has_many :orders, through: :offer_orders

  accepts_nested_attributes_for :offer_items, allow_destroy: true, reject_if: lambda {|a| a[:sku_id].blank?}

  validate :valid_date_sequence

  def self.filtered(filter)
    case filter
    when 'running' then where.not(:status => 'running')
    when 'finished' then where.not(:status => 'finished')
    when 'future' then where.not(:status => 'active')
    else all
    end
  end

  # Returns a scope that sorts the results by the provided field. This behaves
  # close to ::order except that it defaults to sorting by :name.
  #
  # @param [String, nil] sort
  def self.sorted(sort)
    order(sort || :name)
  end

  def self.current
    where("open_at < ? AND ship_at > ?", Date.today, Date.today)
  end

  def self.open
    where("open_at < ? AND close_at > ?", Date.today, Date.today)
  end

  def self.pending
    where("open_at > ?", Date.today)
  end

  def self.closed
    where("close_at < ?", Date.today)
  end

  def self.shipped
    where("ship_at < ?", Date.today)
  end

  def destroyable?
    true
  end

  def open?
    today = Date.today
    close_at > today
    open_at < today
  end

  def shipped?
    today = Date.today
    ship_at < today
  end

  def pending?
    today = Date.today
    open_at > today
  end

  # Can the offer be skipped?
  def skippable?
    open? and min_quantity == 0
  end

  # Can the maximum quantity be adjusted?
  def adjustable_quantity?
    open? and min_quantity != max_quantity
  end

  def candidates
    Member.complete
  end

  # The number of items in the offer
  def sku_total_quantity
    offer_items.to_a.sum(&:quantity)
  end

  # The nominal unit price, based on the number of items and the offer price
  def sku_unit_price
    price / sku_total_quantity
  end

   # Returns a stubbed out offer item which serves as a 'template' for
   # generating new items.
   #
   # @return OfferItem
   def offer_item_template(quantity = 1)
     {quantity: quantity, offer_id: self.id}
   end

   # @param [Money, Numeric, String] price
   #
   # @return Money
   def display_price=(price_value)
    self.price = price_value
   end

   # Return the 'display' price
   #
   # @return Money
   def display_price
     price
   end

   alias_method :original_offer_items_attributes=, :offer_items_attributes=
   # Massage incoming item params before saving
   #
   # @return nil
   def offer_items_attributes=(vals)
     vals.each do |_, val|
        val['_destroy'] = true if val['quantity'].blank? or val['quantity'] == '0'
     end
     self.original_offer_items_attributes = vals
   end

   def valid_date_sequence
     begin
       raise('The open date must be earlier than the close date.') if open_at > close_at
     rescue => exception
       errors.add(:close_at, exception.message)
     end

     begin
       raise('The ship date must be after the close date.') if close_at > ship_at
     rescue => exception
       errors.add(:ship_at, exception.message)
     end
   end

   check_for_extensions
end
