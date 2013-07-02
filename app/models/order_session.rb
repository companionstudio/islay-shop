# This module contains all the logic for dumping an order to a JSON string and
# then later create a new instance of an order from that string.
#
# This is intended to be used for dumping an order into session.
module OrderSession
  # The properties that should be included in a JSON dump of an order.
  DUMP_PROPERTIES = [:name, :phone, :email, :is_gift, :gift_message].freeze

  # The methods that should be included in a JSON dump.
  DUMP_METHODS = [:items_dump, :promo_code].freeze

  def self.included(klass)
    klass.class_attribute :dump_opts
    klass.dump_opts = {
      :root     => false,
      :only     => DUMP_PROPERTIES.dup,
      :methods  => DUMP_METHODS.dup
    }

    klass.send(:extend, ClassMethods)
    klass.send(:include, InstanceMethods)
  end

  module ClassMethods
    # Loads a new instance of an order from a JSON string.
    #
    # @param String json
    #
    # @return Order
    def load(json)
      new(JSON.parse(json))
    end

    # Extends the configuration for dumping an order to JSON.
    #
    # @param Hash opts
    #
    # @return self
    def dump_config(opts)
      if opts[:properties]
        self.dump_opts[:only] = self.dump_opts[:only] + opts[:properties]
      end

      if opts[:methods]
        self.dump_opts[:methods] = self.dump_opts[:methods] + opts[:methods]
      end
      
      self
    end
  end

  module InstanceMethods
    # Dumps the order to a JSON string, which can be rehydrated later using
    # the ::load method.
    #
    # @return String
    def dump
      to_json(self.dump_opts)
    end

    # Dumps the items in the order into a hash, flagging each as either a sku
    # or service item.
    #
    # @return Hash
    def items_dump
      items.map {|item| {:sku_id => item.sku_id, :quantity => item.quantity}}
    end

    # Takes a hash of items and adds them to the rehydrated order.
    #
    # @param Hash attrs
    #
    # @return Array<OrderItem>
    def items_dump=(attrs)
      attrs.each {|i| self.items.build(i).valid?}
    end
  end
end
