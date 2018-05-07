class OrderPayment < ActiveRecord::Base
  include IslayShop::Payments
  extend Forwardable

  belongs_to :order

  # Delegate a bunch of methods to the transaction object provided by
  # SpookAndPay. If you want to see the signatures for these particular
  # methods, please refer to the SpookAndPay::Transaction class.
  def_delegators(
    :transaction, :can_capture?, :can_void?, :can_refund?, :settled?,
    :settling?, :authorized?
  )

  # Checks to see if the authorization has expired, meaning the funds can no
  # longer be captured. Will only be true while the payment is authorized
  # i.e. once funds are captured, no warnings will be raised.
  #
  # @return [true, false]
  def authorization_expired?
    !provider_expiry.nil? and authorized? and authorization_expires_in < 0
  end

  # Checks to see if the auth is expired or about to expire. Will only return
  # true while the payment is authorized i.e. once funds are captured, no
  # warnings will be raised.
  #
  # @return [true, false]
  def authorization_expiry_warning?
    !provider_expiry.nil? and authorized? and authorization_expires_in < 3
  end

  # Calculates how many days are available before the authorization expires i.e.
  # funds will not be able to be captured. This may be a negative number if
  # the auth has expired.
  #
  # A nil value indicates that it never expires. This is provider specific.
  #
  # @return [Integer, nil]
  def authorization_expires_in
    if provider_expiry.nil?
      nil
    else
      ((provider_expiry - Time.now) / 86400).to_i
    end
  end

  # A simple accessor which glues the expiry month and year together.
  #
  # @return String
  def expiry
    "#{expiration_month}/#{expiration_year}"
  end

  # Setter which coerces it's input into a downcased and underscored string.
  #
  # @param String type
  # @return String
  def card_type=(type)
    self[:card_type] = type.downcase.gsub(' ', '_')
  end

  # Captures the funds from the authorized transaction in the payment
  # provider's system.
  #
  # @return [true, false]
  # @raises SpookAndPay::Transaction::InvalidActionError
  def capture!
    handle_result('capture', transaction.capture!)
  end

  # Directly charges the amount to the card in the payment
  # provider's system.
  #
  # @return [true, false]
  # @raises SpookAndPay::Transaction::InvalidActionError
  def purchase!
    handle_result('purchase', payment_provider.purchase_via_credit_card(provider_token, order.total.raw))
  end

  # Voids a pending transaction. Will only work for transactions that are
  # authorized. Captured transactions must be refunded.
  #
  # @return [true, false]
  # @raises SpookAndPay::Transaction::InvalidActionError
  def void!
    handle_result('void', transaction.void!)
  end

  # Refunds a payment. Underlying transaction must be captured first.
  # Transactions that are only authorized should instead be voided.
  #
  # @return [true, false]
  # @raises SpookAndPay::Transaction::InvalidActionError
  def refund!
    handle_result('refund', transaction.refund!)
  end

  private

  # A generic helper for handling results from payment actions.
  #
  # @param String action
  # @param SpookAndPay::Result result
  # @return [true, false]
  def handle_result(action, result)
    @transaction = result.transaction
    update_attributes(:status => transaction.status, :provider_token => transaction.id)
    begin
      @transaction = result.transaction
      update_attributes(:status => transaction.status, :provider_token => transaction.id)
      result.successful?
    rescue ::Braintree::NotFoundError => e
      order.logs.create(:action => 'bill', :succeeded => false, :notes => "Billing failed: #{(result.raw.transaction.status || '').humanize} - #{result.raw.transaction.processor_response_text}")
      false
    end

  end

  # Retrieves the transaction from the remote provider. This is memoised.
  #
  # @return SpookAndPay::Transaction
  def transaction
    @transaction ||= payment_provider.transaction(provider_token)
  end
end
