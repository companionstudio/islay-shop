class SkuPriceLog < ActiveRecord::Base
  include SkuDescription

  belongs_to :sku

  attr_accessible :before, :after

  track_user_edits

  # Returns a scope with calculated fields for who created the log and also,
  # all the fields necessary to summarize a SKU.
  #
  # @return ActiveRecord::Relation
  def self.summary
    select(%{
      before, after, sku_price_logs.created_at,
      skus.name, skus.volume, skus.weight, skus.size,
      CASE
        WHEN sku_price_logs.creator_id IS NULL then 'Customer'
        ELSE (SELECT name FROM users WHERE id = sku_price_logs.creator_id)
      END AS creator_name
    }).joins(:sku)
  end

  # Formats the movement into a money formatted string.
  #
  # @return String
  def formatted_movement
    format_money(movement)
  end

  # Formats the price into a money formatted string.
  #
  # @return String
  def formatted_after
    format_money(after)
  end

  # Formats a float into a monentary formatted string i.e. sticks a '$' in the
  # front and pads the decimals.
  #
  # @param Float value
  #
  # @return String
  def format_money(value)
    "$%.2f" % value
  end

  # How much the price was modified by.
  #
  # @return Float
  def movement
    if before > after
      (before - after).round(2)
    else
      (after - before).round(2)
    end
  end

  # Which direction the price moved in; up/down.
  #
  # @return String
  def direction
    if before > after
      'down'
    else
      'up'
    end
  end
end
