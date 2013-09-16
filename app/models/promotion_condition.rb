class PromotionCondition < ActiveRecord::Base
  include Islay::MetaData
  include Promotions::Config

  belongs_to :promotion

  # Loads effect subclasses by looking for files on disk and kicking off Rails'
  # constant_missing magic by extracting the class name from the file name.
  #
  # Bloody horrible really, but the only way to get the subclasses reliably.
  #
  # @return Array<PromotionCondition>
  def self.condition_classes
    @@condition_classes ||= Dir[File.expand_path('../promotion_*_condition.rb', __FILE__)].map do |f|
      f.match(/(promotion_[a-z_]+_condition)/)[1].classify.constantize
    end
  end

  # Returns an array of effect names which are compatible with this condition.
  #
  # @return Array<Symbol>
  def self.compatible_effects
    Promotions::Scopes.compatible_effects(self)
  end

  # Method is a shortcut to ::compatible_effects
  #
  # @return Array<Symbol>
  def compatible_effects
    self.class.compatible_effects
  end

  # Used to check if the promotion condition succeeds for the provided order.
  # It returns a Result class, which encapsulates success, partial success, 
  # failure and any additional information.
  #
  # For example, in the case of success, the condition may indicate a number of
  # order items it applies to and their quantities. This is to be used by the
  # effects down-stream of the promotion.
  #
  # @param Order order
  # @return PromotionCondition::Result
  def check(order)
    raise NotImplementedError
  end

  # A class for indicating success or failure of a qualification and in the
  # case of failure capturing the reason why it failed.
  class Result
    # The acceptable set of scopes.
    SCOPES = Set.new([:order, :items, :sku_items, :service_items]).freeze

    # The acceptable set of qualifications.
    QUALIFICATION = Set.new([:full, :partial, :none]).freeze

    # Stores the symbol representing the condition
    #
    # @attr_reader Symbol
    attr_accessor :condition

    # The scope of the qualification. It captures if this is a complete 
    # failure, partial qualification or full qualification.
    #
    # @attr_reader Symbol
    attr_accessor :qualification

    # An enum which defines the scope of the condition e.g. does it apply to
    # the whole order, or just a single item?
    #
    # @attr_reader Symbol
    attr_accessor :scope

    # The components of the order affected by the condition.  
    #
    # @attr_reader Hash<OrderItem, Numeric>
    attr_reader :targets

    # Create a new instance.
    #
    # @param Symbol condition
    # @param [:full, :partial, :none] qualification
    # @param [:order, :items, :sku_items, :service_items] scope
    # @param Hash<OrderItem, Numeric> targets
    # @todo Validate the enums against the constants
    def initialize(condition, qualification, scope, targets = {})
      @condition      = condition
      @qualification  = qualification
      @scope          = scope
      @targets        = targets
    end

    # Indicates the success or failure of the qualification.
    #
    # @return [true, false]
    def successful?
      qualification == :full
    end

    # Checks to see if the qualification is partial.
    #
    # @return [true, false]
    def partial?
      qualification == :partial
    end

    # Checks to see if the qualification has failed.
    #
    # @return [true, false]
    def failed?
      qualification == :none
    end
  end

  # Generates a symbol representing the type of condition.
  #
  # @return Symbol
  def short_name
    @short_name ||= self.class.to_s.underscore.match(/^promotion_(.+)_condition$/)[1].to_sym
  end

  private

  # Returns a successful result.
  #
  # @param Hash<OrderItem, Numeric> targets
  # @return Result
  def success(targets = {})
    Result.new(short_name, :full, condition_scope, targets)
  end

  # Generates a partial result.
  # 
  # @param Hash<OrderItem, Numeric> targets
  # @return Result
  def partial(targets = {})
    Result.new(short_name, :partial, condition_scope, targets)
  end

  # Generates a failure result.
  # 
  # @return Result
  def failure
    Result.new(short_name, :none, condition_scope)
  end
end
