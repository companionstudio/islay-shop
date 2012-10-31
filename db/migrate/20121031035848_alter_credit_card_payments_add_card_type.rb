class AlterCreditCardPaymentsAddCardType < ActiveRecord::Migration
  def up
    add_column(:credit_card_payments, :card_type, :string, :limit => 30, :null => false, :default => 'unknown')
    change_column_default(:credit_card_payments, :card_type, nil) 
  end

  def down
    remove_column(:credit_card_payments, :card_type)
  end
end
