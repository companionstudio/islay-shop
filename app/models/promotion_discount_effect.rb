class PromotionDiscountEffect < PromotionEffect
  desc "Order Discount"

  metadata(:config) do
    enum    :kind,    :required => true, :values => %w(fixed percentage)
    integer :amount,  :required => true, :greater_than => 0
  end

  attr_accessible :amount_and_kind

  def amount_and_kind=(input)
    extract = /(\$*)([\d\.]+)(\%*)/.match(input)

    if extract
      if extract[1] == '$'
        self.kind = 'fixed'
        self.amount = extract[2]
      elsif extract[3] == '%'
        self.kind = 'percentage'
        self.amount = extract[2]
      end
    end
  end

  def amount_and_kind
    case kind
    when 'percentage' then "#{amount}%"
    when 'fixed'      then "$#{amount}"
    end
  end

  def apply!(order, qualifications)
    order.discount = case kind
    when 'percentage' then (order.product_total * (amount.to_f / 100)).round(2)
    when 'fixed'      then amount # Amount is in dollars
    end

    order.applied_promotions << applications.build(:promotion => promotion)
  end

end
