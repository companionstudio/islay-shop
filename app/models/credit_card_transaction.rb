class CreditCardTransaction < ActiveRecord::Base
  belongs_to :payment, :class_name => 'CreditCardPayment'
  attr_accessible :amount, :currency, :transaction_type, :transaction_id

  # Checks to see if this transaction was a credit.
  #
  # @return Boolean
  def crediting?
    transaction_type == 'credit'
  end

  # Checks to see if this transaction was an authorization.
  #
  # @return Boolean
  def authorizing?
    transaction_type == 'authorize'
  end

  # Checks to see if this transaction was capturing previously authorized funds.
  #
  # @return Boolean
  def capturing?
    transaction_type == 'capture'
  end

  # Runs a capture transaction. Only valid against authorizing transactions.
  #
  # @return SpookyCore::Transaction
  def capture!
    run_transaction(:capture)
  end

  # Runs a credit transaction. Only valid against capturing transactions.
  #
  # @return SpookyCore::Transaction
  def credit!
    run_transaction(:credit)
  end

  private

  # Generates a new transaction from this transaction's transaction_id.
  #
  # @return SpookyCore::Transaction
  def run_transaction(type)
    SpookyCore::Transaction.create_from_transaction(type, transaction_id)
  end
end
