class PromotionDiscountEffect < PromotionEffect
  desc "Whole Order Discount"
  condition_scope :order
  effect_scope :order

  metadata(:config) do
    enum    :mode,        :required => true, :values => %w(dollar percentage), :default => 'dollar'
    float   :percentage
    money   :dollar
  end

  # Custom accessor for setting percentage or dollar amount.
  attr_accessible :amount

  # Custom validator.
  validate :validate_amount

  # Conditionally returns either a float or a money instance depending on the
  # value of the kind attribute.
  #
  # @return [Float, String]
  def amount
    case mode
    when 'percentage' then percentage
    when 'dollar' then dollar.to_s(:prefix => false, :drop_cents => true)
    end
  end

  # Accessor for amount which calls the #reassign helper for toggling between
  # dollar or percentage modes.
  #
  # @param [String, Numeric] n
  # @return [String, Numeric]
  def amount=(n)
    @amount = n
    reassign
    n
  end

  # Alais the original mode so we can inject our own logic.
  alias :original_mode= :mode=

  # Custom accessor for writing the mode which coerces input and calls the 
  # #reassign helper.
  #
  # @param String k
  # @return String
  def mode=(k)
    self.original_mode = k
    reassign
    k
  end

  # Shortcut which returns a formatted string representing either the 
  # percentage or dollar amount.
  #
  # @return String
  def amount_and_mode
    case mode
    when 'percentage' 
      if percentage.to_i == percentage
        "#{percentage.to_i}%"
      else
        "#{percentage}%"
      end
    when 'dollar'
      dollar.to_s(:drop_cents => true)
    end
  end

  # Reassigns values based on the value of the mode attribute.
  #
  # @return nil
  def reassign
    case mode
    when 'percentage'
      self.dollar = nil
      self.percentage = @amount || self.percentage
    when 'dollar'
      self.percentage = nil
      self.dollar = @amount || self.dollar
    end

    nil
  end

  # Either the percent or dollar attributes must have a value in them.
  #
  # @return nil
  def validate_amount
    if (mode == 'percentage' and percentage.nil?) or (mode == 'dollar' and (dollar.nil? or dollar.zero?))
      errors.add(:amount, "required")
    end

    nil
  end

  def apply!(order, qualifications)
    case mode
    when 'percentage' 
      order.enqueue_adjustment(:percentage_discount, BigDecimal.new(percentage.to_s), 'promotion')
      result("Applied a #{percentage}% discount")
    when 'dollar'
      order.enqueue_adjustment(:fixed_discount, dollar, 'promotion')
      result("Applied a #{dollar} discount")
    end
  end
end
