class PromotionCondition < ActiveRecord::Base
  include Islay::MetaData
  include IslayShop::PromotionConfig

  belongs_to :promotion

  def sku_qualifies?(sku)
    false
  end

  def product_qualifies?(product)
    false
  end

  def category_qualifies?(category)
    false
  end

  def qualifies?(order)
    raise NotImplementedError
  end

  def qualifications(order)
    {}
  end

  # A class for indicating success or failure of a qualification and in the
  # case of failure capturing the reason why it failed.
  class Result
    # Stores the symbol representing the condition
    attr_accessor :condition

    # Stores the symbol representing the reason for the failure.
    attr_accessor :reason

    # Create a new instance.
    #
    # @param Symbol condition
    # @param Boolean success
    # @param Symbol reason
    def initialize(condition, success, reason = nil)
      @condition = condition
      @success = success
      @reason = reason
    end

    # Indicates the success or failure of the qualification.
    #
    # @return Boolean
    def success?
      @success
    end
  end

  # Generates a symbol representing the type of condition.
  #
  # @return Symbol
  def short_name
    @short_name ||= self.class.to_s.underscore.match(/^promotion_(.+)_condition$/)[1].to_sym
  end

  private

  # A helper method for constructing the result object.
  #
  # @param Boolean success
  # @param Symbol reason
  #
  # @return QualificationResult
  def result(success, reason = nil)
    Result.new(short_name, success, reason)
  end

  # Force the subclasses to be loaded
  Dir[File.expand_path('../promotion_*_condition.rb', __FILE__)].each {|f| require f}
end
