module Promotions
  # This module provides methods for defining and accessing configuration. It
  # is mixed into both the PromotionCondition and PromotionEffect abstract
  # classes.
  module Config
    # The hook is used to stub out configuration and do some metaprogramming
    # against the target class.
    #
    # @param [PromotionEffect, PromotionCondition] klass
    # @return nil
    def self.included(klass)
      klass.class_eval do
        class_attribute :promo_config
        # attr_accessible   :active, :type
        after_initialize  :set_active
        attr_reader       :active

        include InstanceMethods
        extend ClassMethods
      end

      # This nasty stuff here is a way of making STI work with nested_attributes.
      # Basically, you can pass in :type when initializing a model and it will
      # return an instance.
      class << klass
        def new_with_cast(*a, &b)
          if (h = a.first).is_a? Hash and (type = h[:type] || h['type']) and (klass = type.constantize) != self
            raise "You cannot specify that type" unless klass < self
            klass.new(*a, &b)
          else
            new_without_cast(*a, &b)
          end
        end

        alias_method_chain :new, :cast
      end

      nil
    end

    module InstanceMethods
      # Accessor which returns the position configured against the promotion
      # component's class.
      #
      # @return Integer
      def position
        promo_config[:position]
      end

      # Accessor which returns the desc configured against the promotion
      # component's class.
      #
      # @return Integer
      def desc
        promo_config[:desc]
      end

      # Accessor which returns the condition scope configured against the
      # promotion component's class.
      #
      # @return Symbol
      def condition_scope
        promo_config[:condition_scope]
      end

      # Accessor which returns the effect scope configured against the
      # promotion component's class.
      #
      # @return Symbol
      def effect_scope
        promo_config[:effect_scope]
      end

      # Writer for setting the active flag. It coerces a range of inputs into a
      # boolean. Typically these values will come in via forms.
      #
      # @param [String, Numeric, true, false] b
      # @return [true, false]
      def active=(b)
        @active = case b
        when true, false then b
        when 0, '0' then false
        when 1, '1' then true
        end
      end

      private

      # An after_initialze hook which ensures that @active has a value set by
      # default.
      #
      # @return [true, false]
      def set_active
        @active ||= !new_record?
      end
    end

    module ClassMethods
      # When the promotion component is inherited, we need to ensure that it's
      # configuration is initialized with defaults.
      #
      # @param Class klass
      def inherited(klass)
        klass.promo_config = {
          :condition_scope => :order,
          :effect_scope    => :order
        }
        super
      end

      # Sets the condition scope for the promotion components. For conditions
      # this communicates the portion of the order it examines. For effects
      # this specifies a requirement for corresponding conditions with the same
      # scope.
      #
      # @param Symbol s
      # @return Symbol
      def condition_scope(s)
        self.promo_config[:condition_scope] = s
      end

      # Sets the effect scope for the promotion components. For effects, this
      # specifies the portion of the order to which it will apply it's effects.
      #
      # @param Symbol s
      # @return Symbol
      def effect_scope(s)
        self.promo_config[:effect_scope] = s
      end

      # Configures a short description.
      #
      # @param String s
      # @return String
      def desc(s)
        self.promo_config[:desc] = s
      end

      # Configures the desired position of a component relative to it's
      # siblings. Default orderings are often unclear, so this lets us enforce
      # a specific order globally.
      #
      # @param Integer p
      # @return Integer
      def position(p)
        self.promo_config[:position] = p
      end
    end # ClassMethods
  end # Config
end # Promotions
