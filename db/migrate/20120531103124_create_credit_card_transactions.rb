class CreateCreditCardTransactions < ActiveRecord::Migration[4.2]
  def change
    create_table :credit_card_transactions do |t|
      t.integer :credit_card_payment_id,  :null => false, :on_delete => :cascade
      t.string  :transaction_id,          :null => false, :limit => 60, :references => nil
      t.string  :transaction_type,        :null => false, :limit => 50
      t.float   :amount,                  :null => false, :precision => 7, :scale => 2
      t.string  :currency,                :null => false, :limit => 4, :default => 'AUD'

      t.timestamps
    end
  end
end
