class PromotionGetNFreeEffect < PromotionEffect
  desc "Buy One, Get One (or more) Free"

  metadata(:config) do
    integer :quantity,  :required => true, :greater_than => 0, :default => 1
  end

  def apply!(order, qualifications)
    qualifications.each do |id, count|
      qualifying_item = order.add_free_item(sku_id, count)

      applications.build(
        :promotion              => promotion,
        :order                  => order,
        :qualifying_order_item  => qualifying_item
      )
    end
  end
end
