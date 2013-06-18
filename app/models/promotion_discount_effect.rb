class PromotionDiscountEffect < PromotionEffect
  desc "Whole Order Discount"

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
      else
        raise ArgumentError, 'Your discount must be either a dollar amount, or a percentage.'
      end
    else
      raise ArgumentError, 'Your discount must be either a dollar amount, or a percentage.'
    end
  end

  def amount_and_kind
    case kind
    when 'percentage' then "#{amount}%"
    when 'fixed'      then "$#{amount}"
    end
  end

  def apply!(order, qualifications)
    order.product_total = case kind
    when 'percentage' then order.product_total - (order.product_total * (amount.to_f / 100)).round(2)
    when 'fixed'      then order.product_total - (amount / 100) # Amount is in dollars
    end

    if !order.shipping_total.blank? and order.shipping_total > 0
      order.shipping_total = case kind
      when 'percentage' then order.shipping_total - (order.shipping_total * (amount.to_f / 100)).round(2)
      end
    end
  end
end
