module Promotions
  # Module which defines accessors and configuration for any promotion effects
  # that implement some form of discounting.
  module DiscountEffectConfig
    # This handler is used to define an amount and a kind metadata attribute.
    #
    # @param PromotionEffect
    # @return nil
    def self.included(klass)
      klass.class_eval do
        metadata(:config) do
          enum  :mode, :required => true, :values => %w(dollar percentage), :default => 'dollar'
          float :percentage
          money :dollar
        end

        # Custom accessor for setting percentage or dollar amount.
        attr_accessible :amount

        # Custom validator.
        validate :validate_amount

        # Alias the original mode so we can inject our own logic.
        alias :original_mode= :mode=
        alias :mode= :reassigning_mode=
      end

      nil
    end

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

    # Custom accessor for writing the mode which coerces input and calls the 
    # #reassign helper.
    #
    # @param String k
    # @return String
    def reassigning_mode=(k)
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

    private

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
      if (mode == 'percentage' and (percentage.nil? or percentage == 0)) or (mode == 'dollar' and (dollar.nil? or dollar.zero?))
        errors.add(:amount, "required")
      end

      nil
    end
  end
end
