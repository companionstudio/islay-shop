class SkuPricePoint < ActiveRecord::Base
  extend SpookAndPuff::MoneyAttributes
  attr_money :price

  belongs_to  :sku
  has_many    :order_items, :class_name => 'OrderSkuItem'

  validate :volume, :presence   => true, :numericality => {:only_integer => true, :greater_than => 0}
  validate :price,  :presence   => true
  validate :mode,   :inclusion  => {:in => %w(single boxed bracketed)}

  attr_accessible(:current, :valid_from, :valid_to, :price, :volume, :mode, :display_price)

  track_user_edits

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
end
