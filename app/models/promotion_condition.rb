class PromotionCondition < ActiveRecord::Base
  belongs_to :promotion

  class_attribute :_desc, :definitions
  attr_accessor :active
  attr_accessible :active
  after_initialize :set_active

  def set_active
    active = false if active.nil?
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
