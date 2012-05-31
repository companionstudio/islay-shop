class CreateCreditCardPayments < ActiveRecord::Migration
  def change
    create_table :credit_card_payments do |t|
      t.integer   :order_id,        :null => false, :on_delete => :cascade
      t.boolean   :successful,      :null => false, :default => false
      t.integer   :amount,          :precision => 7,  :scale => 2,  :null => false
      t.string    :first_name,      :limit => 200,  :null => false
      t.string    :last_name,       :limit => 200,  :null => false
      t.string    :number,          :limit => 25,   :null => false
      t.integer   :month,           :limit => 7,    :null => false
      t.integer   :year,            :limit => 7,    :null => false
      t.string    :gateway_id,      :limit => 60,   :null => false, :references => nil
      t.timestamp :gateway_expiry,  :null => false

      t.timestamps
    end
  end
end
