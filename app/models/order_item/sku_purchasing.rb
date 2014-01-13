class OrderItem
  module SkuPurchasing
    include OrderItem::Purchasing

    def find_item(sku_or_id)
      id = sku_or_id.is_a?(Sku) ? sku_or_id.id : sku_or_id
      select {|i| i.sku_id == id}.first
    end

    # @todo Actually implement this guy.
    def purchase_stock!
      each do |item|
        item.sku.purchase_stock!(proxy_association.owner.id, item.quantity)
      end
    end

    private

    # @todo The predicate to check quantity seems a bit dodgy. Implies an error in
    # #price_points method.
    def assign_components(entry, purchase, quantity)
      price_points(purchase, quantity).each do |p|
        quantity = p.first
        price    = p.last.price

        if quantity > 0
          entry.components.build(
            :price              => price,
            :quantity           => quantity,
            :total              => price * quantity,
          )
        end
      end
    end

    def regular_price_point(purchase)
      purchase.price_points.where(:volume => 1, :mode => 'single').first
    end

    # Based on the SKU and the quantity, this method collects potential matching
    # price points and them divides the quantity amoungst them based on the
    # following rules:
    #
    # @param Sku purchase
    # @param Integer quantity
    #
    # @return Array<Array<Integer, SkuPricePoint>>
    def price_points(purchase, quantity)
      conditions  = "current = true AND ((mode IN ('bracketed', 'boxed') AND ? >= volume) OR mode = 'single')"
      points      = purchase.price_points.where(conditions, quantity).group_by(&:mode)
      boxed       = points['boxed']
      single      = points['single'].first

      if points.has_key?('bracketed')
        [[quantity, points['bracketed'].first]]
      elsif !boxed or boxed.empty?
        [[quantity, single]]
      else
        n = quantity
        points = []

        boxed.sort {|x, y| y.volume <=> x.volume}.each do |point|
          if n > 0
            rm = n % point.volume
            points << [n - rm, point]
            n = rm
          end
        end

        if n > 0
          points << [n, single]
        end

        points
      end
    end

    def stock_available?(sku, n)
      sku.sufficient_stock?(n)
    end

    def maximum_quantity_allowed(sku)
      sku.stock_level
    end

    def find_or_create_item(sku)
      find_item(sku) || build(:sku => sku)
    end
  end
end
