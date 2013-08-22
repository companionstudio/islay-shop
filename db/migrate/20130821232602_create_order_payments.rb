class CreateOrderPayments < ActiveRecord::Migration
  def change
    create_table :order_payments do |t|
      t.integer   :order_id,          :null => false, :on_delete => :cascade
      t.string    :provider_name,     :null => false, :length => 25 # braintree, spreedly_core etc
      t.string    :provider_token,    :null => false, :length => 255
      # Indicates when actions can no long be run against a transaction. 
      # NULL indicates that it never expires
      t.timestamp :provider_expiry,   :null => true 
      t.string    :status,            :null => false, :length => 25 # authorized, captured etc
      t.string    :name,              :null => true,  :length => 255
      t.string    :number,            :null => false, :length => 35 # Obfuscated number
      t.integer   :expiration_month,  :null => false, :length => 2
      t.integer   :expiration_year,   :null => false, :length => 4
      t.string    :card_type,         :null => false, :length => 25

      t.timestamps
    end
  end
end
