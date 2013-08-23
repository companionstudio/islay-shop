# This class is a convenience for working with remote payment providers via 
# transparent redirect. It is part of a set of classes and modules which 
# wrap around the functionality provided by the SpookAndPay gem.
class PaymentSubmission
  # Set up naming. This is requried by the Errors class.
  extend ActiveModel::Naming 
  attr_accessor :name

  # Basic set of readers
  attr_reader :errors, :transaction, :credit_card

  # The basic set of fields.
  FIELDS = [:name, :number, :expiration_month, :expiration_year, :cvv].freeze

  # Generate readers for the fields
  attr_reader *FIELDS

  # An instance of this class serves as a template for new payment submissions
  # and encapsulates the values and errors returned when a submission fails.
  #
  # @param [SpookAndPay::Result, nil] result
  def initialize(result = nil)
    @errors = ActiveModel::Errors.new(self)

    if result
      FIELDS.each {|f| instance_variable_set(:"@#{f}", result.credit_card.send(f))}
      set_errors(result.errors_for(:credit_card)) if result.failure?
      @transaction = result.transaction
      @credit_card = result.credit_card
    end
  end

  # Checks to see if any errors have been set.
  #
  # @return [true, false]
  def valid?
    errors.empty?
  end

  # Takes a hash of error messages and adds them to the errors object. This
  # is because the submission doesn't do any validation of it's own. That is
  # handled by the remote provider.
  #
  # The hash should be keyed by symbols and the values arrays of strings.
  #
  # @param Hash<Symbol, Array<String>>
  # @return ActiveModel::Errors
  def set_errors(messages)
    pairs = messages.map {|k, v| v.map {|m| [k, m]}}.flatten(1)
    pairs.each {|p| errors.add(p.first, p.last.message)}
    errors
  end
end
