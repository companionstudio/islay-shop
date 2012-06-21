class PromotionGetNFreeEffect < PromotionEffect
  desc "Buy One, Get One (or more) Free"

  metadata(:config) do
    integer :quantity,  :required => true, :greater_than => 0, :default => 1
  end

  def apply!(order, qualifications)
    qualifications.each do |id, count|
      bonus = order.add_bonus_item(id, count)

      applications.build(
        :promotion         => promotion,
        :order             => order,
        :bonus_item  => bonus
      )
    end
  end
end
