class PromotionDiscountEffect < PromotionEffect
  desc "Whole Order Discount"

  metadata(:config) do
    enum    :kind,    :required => true, :values => %w(fixed percentage)
    string  :amount,  :required => true, :greater_than => 0
  end

  attr_accessible :amount_and_kind

  # A setter which sets the kind/mode and amount based on the input string.
  #
  # @param String input
  # @return string
  # @raises ArgumentError
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

  # Returns a formatted string
  #
  # @return String
  def amount_and_kind
    case kind
    when 'percentage' then "#{amount}%"
    when 'fixed'      then "$#{amount}"
    end
  end

  def apply!(order, qualifications)
    case kind
    when 'percentage' 
      order.enqueue_adjustment(:percentage_discount, BigDecimal.new(amount), 'promotion')
    when 'fixed'
      order.enqueue_adjustment(:fixed_discount, SpookAndPuff::Money.new(amount), 'promotion')
    end

    result("Applied a #{amount_and_kind} discount")
  end
end
