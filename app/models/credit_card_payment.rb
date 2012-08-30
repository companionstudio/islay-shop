class CreditCardPayment < ActiveRecord::Base
  belongs_to  :order
  has_many    :transactions,        :class_name => 'CreditCardTransaction'
  has_one     :latest_transaction,  :class_name => "CreditCardTransaction", :order => "created_at DESC"

  validations_from_schema :except => [:gateway_id]
  validates :verification_value, :presence => true, :if => :new_record?
  validate  :check_card_number, :if => :number_changed?
  before_validation :set_payment_details

  attr_accessor :verification_value

  attr_accessible(
    :first_name, :last_name, :number, :verification_value,
    :month, :year, :gateway_id, :amount, :gateway_expiry
  )

  # Authorizes a payment. This doesn't bill a card, but essentially says 'hey
  # let me hold onto this'.
  #
  # @return Boolean
  def authorize!
    result = payment_method.send(:authorize, total_in_cents, 'AUD')
    log_result(result, :authorize)
  end

  # Captures/bills money which has previously been authorized. It cannot be
  # called on payment methods that have already been captured.
  #
  # @return Boolean
  def capture!
    result = latest_transaction.capture!
    log_result(result, :capture)
  end

  # Cancels a payment method. Authorized method are allowed to lapse. Captured
  # funds are credited.
  #
  # @return Boolean
  def cancel!
    if latest_transaction.authorizing?
      true
    elsif latest_transaction.capturing?
      result = latest_transaction.credit!
      log_result(result)
    end
  end

  private

  # Converts the total from dollars to cents, since some gateways/processors
  # require it.
  #
  # @return Integer
  def total_in_cents
    (amount * 100).to_i
  end

  # Looks up the payment method on Spreedly Core.
  #
  # @return SpookyCore::PaymentMethod
  def payment_method
    @payment_method ||= SpookyCore::PaymentMethod.find(gateway_id)
  end

  # Logs a transaction in the DB.
  #
  # @param [SpookyCore::Transaction, SpookyCore::PaymentMethod] result
  # @param Symbol transaction
  #
  # @return Boolean
  def log_result(result, transaction)
    transactions.build(
      # :successful       => result.succeeded?,
      :amount           => amount,
      :currency         => 'AUD',
      :transaction_type => transaction,
      :transaction_id   => result.token
    )

    unless result.succeeded?
      errors.add :base, result.message
    end

    result.succeeded?
  end

  # Checks to see if SpreedlyCore has returned an error for the card number
  # e.g. it is invalid. Stores the error against the number attribute.
  #
  # @return [String, nil]
  def check_card_number
    if payment_method.errors[:number]
      errors.add(:number, payment_method.errors[:number])
    end
  end

  # Pulls the payment details from the record stored at SpreedlyCore and stores
  # them against the corresponding attributes.
  #
  # @return Hash
  def set_payment_details
    self.attributes = {
      :gateway_expiry     => Time.now.next_month,
      :number             => payment_method.number,
      :first_name         => payment_method.first_name,
      :last_name          => payment_method.last_name,
      :month              => payment_method.month,
      :year               => payment_method.year,
      :verification_value => payment_method.verification_value
    }
  end
end
