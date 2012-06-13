class PromotionCondition < ActiveRecord::Base
  belongs_to :promotion

  class_attribute :_desc, :definitions
  attr_accessor :active
  attr_accessible :active, :type
  after_initialize :set_active

  # This nasty stuff here is a way of making STI work with nested_attributes.
  # Basically, you can pass in :type when initializing a model and it will
  # return an instance.
  class << self
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

  def set_active
    self.active = !new_record? if active.nil?
  end

  def qualifies?(order)
    raise NotImplementedError
  end

  def desc
    _desc
  end

  def self.inherited(klass)
    self.definitions ||= []
    self.definitions << klass
    self.definitions.sort! {|x, y| x._desc > y._desc}
  end

  private

  def self.desc(s)
    self._desc = s
  end

  # Force the subclasses to be loaded
  Dir[File.expand_path('../promotion_*_condition.rb', __FILE__)].each {|f| require f}
end
