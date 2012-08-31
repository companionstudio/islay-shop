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

  # Does what it says on the tin. Concatenates the first and last name.
  #
  # @return String
  def full_name
    "#{first_name} #{last_name}"
  end

  # Concatenates the month and year into the standard MM/YYYY format.
  #
  # @return String
  def expiry
    "#{month}/#{year}"
  end

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

  # Credits a previously captured/billed payment.
  #
  # @return Boolean
  def credit!
    result = latest_transaction.credit!
    log_result(result, :credit)
  end

  # Indicates if the payment is in an authorized state. Once the payment is
  # captured or credited, this will no longer be true.
  #
  # @return Boolean
  def authorized?
    latest_transaction.authorizing?
  end

  # Indicates if the payment is in an captured state. If the payment is
  # credited/refunded, this will no longer be true.
  #
  # @return Boolean
  def captured?
    latest_transaction.capturing?
  end

  # Indicates if the payment has been credited.
  #
  # @return Boolean
  def credited?
    latest_transaction.crediting?
  end

  # Indicates if any authorized funds can be captured.
  #
  # @return Boolean
  def capturable?
    authorized? and !expired?
  end

  # Indicates if this payment method can be credited. For this to be to, the
  # funds need to have been captured and the payment method is not expired.
  #
  # @return Boolean
  def creditable?
    captured? and !expired?
  end

  # Checks to see if the authorization has expired, meaning the funds can no
  # longer be captured. Will only be true while the payment is authorized
  # i.e. once funds are captured, no warnings will be raised.
  #
  # @return Boolean
  def authorization_expired?
    authorized? and authorization_expires_in < 0
  end

  # Checks to see if the auth is expired or about to expire. Will only return
  # true while the payment is authorized i.e. once funds are captured, no
  # warnings will be raised.
  #
  # @return Boolean
  def authorization_expiry_warning?
    authorized? and authorization_expires_in < 3
  end

  # Calculates how many days are available before the authorization expires i.e.
  # funds will not be able to be captured. This may be a negative number if
  # the auth has expired.
  #
  # @return Integer
  def authorization_expires_in
    ((gateway_expiry - Time.now) / 86400).to_i
  end

  # Indicates if any more transactions can be run agains the payment method.
  # SpreedlyCore currently has a window of 30 days, there after the method
  # expires — unless retained, but we don't support that.
  #
  # @return Boolean
  def expired?
    gateway_expiry < 30.days.ago
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
    log = transactions.build(
      # :successful       => result.succeeded?,
      :amount           => amount,
      :currency         => 'AUD',
      :transaction_type => transaction,
      :transaction_id   => result.token
    )

    unless new_record?
      log.save!
    end

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
