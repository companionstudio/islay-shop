class PromotionGetNFreeEffect < PromotionEffect
  desc "Buy One, Get One (or more) Free"

  metadata(:config) do
    integer :quantity,  :required => true, :greater_than => 0, :default => 1
  end

  def apply!(order, qualifications)
    qualifications.each do |sku_id, count|
      order.add_item(sku_id, count * quantity)
    end
  end
end
