class PromotionCondition < ActiveRecord::Base
  belongs_to :promotion
  attr_accessible :config

  class_attribute :_default_option, :options
  self.options = {}

  validate :check_config

  # TODO: Investigate using ActiveModel validations to check the keys.
  # Could be a nice shortcut
  class Option
    def initialize(&blk)
      @keys = {}
      instance_eval(&blk) if block_given?
    end

    def key(type, name)
      @key[name] = type
    end

    def qualification(method = nil, &blk)
      @qualification = method ? method : blk
    end

    def qualifies?(condition, order)
      case @qualification
      when Symbol then condition.send(symbol, order)
      when Proc   then condition.instance_eval(&@qualification)
      end
    end
  end

  def self.default_option
    self._default_option ||= Option.new
  end

  def self.option(name, &blk)
    self.options[name.to_s] = Option.new(&blk)
  end

  def key(type, name)
    default_option.key(type, name)
  end

  def qualification(method = nil, &blk)
    default_option.qualification(method, &blk)
  end

  def qualifies?(order)
    config = self.options[option]
    config.qualifies?(self, order)
  end

  private

  def check_config
    # Look at the current option and it's keys
    # Make sure the required keys are there
    # coerce them if necessary. validate them.
    # They may also have restrictions on range or specific values

    # Have a cry if they're wrong.
  end
end
