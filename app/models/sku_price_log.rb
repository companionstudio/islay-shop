class SkuPriceLog < ActiveRecord::Base
  include SkuDescription

  belongs_to :sku

  attr_accessible(
    :price_before, :price_after, :batch_size_before, :batch_price_before,
    :batch_size_after, :batch_price_after
  )

  track_user_edits

  # Returns a scope with calculated fields for who created the log and also,
  # all the fields necessary to summarize a SKU.
  #
  # @return ActiveRecord::Relation
  def self.summary
    select(%{
      sku_id, price_before, price_after, batch_size_before, batch_size_after,
      batch_price_before, batch_price_after, sku_price_logs.created_at,
      (SELECT short_desc FROM skus WHERE skus.id = sku_id) AS short_desc,
      CASE
        WHEN sku_price_logs.creator_id IS NULL then 'Customer'
        ELSE (SELECT name FROM users WHERE id = sku_price_logs.creator_id)
      END AS creator_name
    })
  end


  def price_moved?
    price_after != price_before
  end

  def batch_size_moved?
    batch_size_after != batch_size_before
  end

  def batch_price_moved?
    batch_price_after != batch_price_before
  end

  # Formats the price_before into a money formatted string.
  #
  # @return String
  def formatted_price_before
    format_money(price_after)
  end

  # Formats the price_after into a money formatted string.
  #
  # @return String
  def formatted_price_after
    format_money(price_after)
  end

  # Formats the batch_price_after into a money formatted string.
  #
  # @return String
  def formatted_batch_price_after
    format_money(batch_price_after)
  end

  # Formats the batch_price_before into a money formatted string.
  #
  # @return String
  def formatted_batch_price_before
    format_money(batch_price_before)
  end

  # Which direction the price moved in; up/down.
  #
  # @return String
  def price_direction
    direction(:price)
  end

  # Which direction the batch size moved in; up/down.
  #
  # @return String
  def batch_size_direction
    direction(:batch_size)
  end

  # Which direction the batch price moved in; up/down.
  #
  # @return String
  def batch_price_direction
    direction(:batch_price)
  end

  private

  # A helper for generating a string represenation of a value's movement i.e.
  # up/down
  #
  # @return String
  def direction(attr)
    if self[:"#{attr}_before"].blank?
      'set'
    elsif self[:"#{attr}_after"].blank?
      'clear'
    elsif self[:"#{attr}_before"] > self[:"#{attr}_after"]
      'down'
    else
      'up'
    end
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
end
