class SkuPricePoint < ActiveRecord::Base
  extend SpookAndPuff::MoneyAttributes
  attr_money :price
  belongs_to  :sku
  has_one  :product, through: :sku
  validates :volume, :presence   => true, :numericality => {:only_integer => true, :greater_than => 0}
  validates :mode,   :inclusion  => {:in => %w(single boxed bracketed)}
  validate :validates_price
  track_user_edits

  action_log_url_params :url_params

  # Returns an ActiveRecord::Relation with a bunch of joins and calculated
  # fields necessary for summarising each price point e.g. SKU, if it's
  # current etc.
  #
  # @return ActiveRecord::Relation
  def self.summary
    select(%{
      (SELECT short_desc FROM skus WHERE skus.id = sku_price_points.sku_id) AS sku_short_desc,
      (SELECT name FROM users WHERE users.id = sku_price_points.creator_id) AS creator_name,
      (SELECT name FROM users WHERE users.id = sku_price_points.updater_id) AS updater_name,
      sku_price_points.*
    })
  end

  # Returns an ActiveRecord::Relation with the results scoped to the current
  # price points.
  #
  # @return ActiveRecord::Relation
  def self.current
    where(:current => true)
  end

  # Looks up the current price for a single SKU.
  #
  # @return SkuPricePoint
  def self.regular_price
    where(:volume => 1).first
  end

  # Returns a relation with the results scoped to the prices at volume i.e.
  # volumes greater than one.
  #
  # @return ActiveRecord::Relation
  def self.volume_prices
    where("volume > 1 and mode != 'bracketed'").order('volume ASC')
  end

  # Looks up the price for the specified quantity.
  #
  # @param Integer quantity
  #
  # @return SkuPricePoint
  def self.price_for(quantity)
    where("volume >= ?", quantity).order('volume ASC').first
  end

  # A predicate which checks to see if the price point is in 'single' mode.
  #
  # @return [true, false]
  def single?
    mode == 'single'
  end

  # Returns a human-readable fragment describing the mode of the price point
  # e.g. for single volume is says 'each'.
  #
  # @return String
  def mode_desc
    case mode
    when 'single'     then 'each'
    when 'bracketed'  then "for #{volume} or more"
    when 'boxed'      then "for every #{volume}"
    end
  end

  # For a boxed price point, the price for a box of the given volume
  #
  # @return SpookAndPuff::Money
  def boxed_price
    if mode == 'boxed'
      price * volume
    else
      raise "Boxed prices are only available on boxed price points"
    end
  end

  # Set the unit price by calculating from a box price
  #
  # @param [Money, Numeric, String] box_price
  #
  # @return SpookAndPuff::Money
  def boxed_price=(box_price)
    if mode == 'boxed'
      self.price = SpookAndPuff::Money.new(box_price) / volume
    else
      raise "Boxed prices are only available on boxed price points"
    end
  end

  # Set the unit price dependent on the mode (either boxed or unit price)
  #
  # @param [Money, Numeric, String] price
  #
  # @return MaggieBeer::Money
  def display_price=(price_value)
    case mode
    when 'boxed'
      self.boxed_price = price_value
    else
      self.price = price_value
    end
  end

  # Return the 'display' price dependent on the mode (either boxed or unit price)
  #
  # @return MaggieBeer::Money
  def display_price
    case mode
    when 'boxed' then boxed_price
    else price
    end
  end

  # This always returns false. It is a convenience for displaying price points
  # in forms.
  #
  # @return false

  def expire
    false
  end

  # Used to prevent price points from having thier price changed.
  class PriceIsImmutableError < StandardError
    # Provides a custom message for this error
    #
    # @return String
    def to_s
      "Price cannot be modified on existing price points."
    end
  end

  # Returns the saving on a purchase of this volume when compared to the provided point.
  #
  # @param SkuPricePoint point
  #
  # @return SpookAndPuff::Money
  def saving(point)
    (point.price * volume) - (price * volume)
  end

  # Returns the saving when compared to the provided point.
  #
  # @param SkuPricePoint point
  #
  # @return SpookAndPuff::Money
  def unit_saving(point)
    point.price - price
  end

  # Returns the percentage saving when compared to the provided point.
  #
  # @param SkuPricePoint point
  #
  # @return String
  def unit_saving_percentage(point)
    "#{100 - point.price.proportion(price).round(1)}%"
  end

  def url_params
    [product, sku]
  end

  private

  # This validates the price. Since the price will actually be a Money
  # instance, we need a custom validator. The build in validators are for
  # floats and integers. Additionlly, the errors are associated with a custom
  # attribute.
  #
  # @return nil
  def validates_price
    if price.zero?
      errors.add(:display_price, "cannot be zero")
    end

    nil
  end
end
