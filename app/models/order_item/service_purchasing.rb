class OrderItem
  module ServicePurchasing
    include OrderItem::Purchasing

    def find_item(service_or_id)
      id = service_or_id.is_a?(Service) ? service_or_id.id : service_or_id
      select {|i| i.service_id == id}.first
    end

    def purchase_stock!
      nil
    end

    private

    def assign_components(entry, purchase, quantity)
      point = purchase.price_points.where(:current => true).first

      entry.components.build(
        :price     => point.price,
        :quantity  => quantity,
        :total     => point.price * quantity,
      )
    end

    def stock_available?(service, n)
      true
    end

    def purchase_limited?(purchase)
      false
    end

    def maximum_quantity_allowed(purchase)
      Float::INFINITY
    end

    def find_or_create_item(service)
      find_item(service) || build(:service => service)
    end
end
end
