class StockControl
  # Checks to see if the specified SKUs are in stock.
  #
  # @param Array<Integer>
  # @returns Hash{Integer => Boolean}
  def self.in_stock?(ids)
    skus(ids).inject({}) {|h, s| h[s.id] = s.stock_level > 0; h}
  end

  # Checks to see if there is sufficient stock of the specified SKUs.
  #
  # @param Hash{Integer => Integer}
  # @returns Hash{Integer => Boolean}
  def self.sufficient_stock?(skus)
    skus(skus.keys).inject({}) do |h, s|
      h[s.id] = s.stock_level > skus[s.id]
      h
    end
  end

  # The stock levels for the specified SKUs.
  #
  # @param Array<Integer>
  # @returns Hash{Integer => Integer}
  def self.stock_levels(ids)
    skus(ids).inject({}) {|h, s| h[s.id] = s.stock_level; h}
  end

  # Updates the stock levels for the specified SKUs, with logging. The logs
  # track the up or down movement of the stocks and who adjusted them.
  #
  # @param Hash{Integer => Integer}
  # @returns Boolean
  def self.update!(skus)

  end

  # Decrements the stock levels for the specified SKUs, logging them as purchases.
  #
  # @param Hash{Integer => Integer}
  # @returns Boolean
  def self.purchase!(skus)

  end

  # Increments the stock levels for the specified SKUs, logging them as returns.
  #
  # @param Hash{Integer => Integer}
  # @returns Boolean
  def self.return!(skus)

  end

  private

  # A helper for returning a collection of SKUs to be manipulated in some way.
  #
  # @param Array<Integer>
  # @returns Array<Sku>
  def skus(ids)
    Sku.select('id, stock_level').where(:id => ids)
  end
end
