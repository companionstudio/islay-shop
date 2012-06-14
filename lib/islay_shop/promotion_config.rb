module IslayShop
  module PromotionConfig
    def self.included(klass)
      klass.class_eval do
        class_attribute   :_desc, :definitions
        attr_accessible   :active, :type
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
    end

    module InstanceMethods
      def set_active
        @active ||= !new_record?
      end

      def active=(b)
        @active = case b
        when true, false then b
        when 0, '0' then false
        when 1, '1' then true
        end
      end

      def desc
        _desc
      end
    end

    module ClassMethods
      def inherited(klass)
        self.definitions ||= []
        self.definitions << klass
      end

      private

      def desc(s)
        self._desc = s
      end
    end #ClassMethods
  end # PromotionsConfig
end # Islay
