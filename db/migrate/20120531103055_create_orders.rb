class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.integer   :person_id,             :null => true, :on_delete => :set_null

      t.string    :status,                :limit => 50, :null => false, :default => 'open'
      t.string    :reference,             :limit => 11, :null => false, :unique => true

      t.string    :name,                  :limit => 200,  :null => false
      t.string    :phone,                 :limit => 50
      t.string    :email,                 :limit => 200,  :null => false
      t.boolean   :is_gift,               :default => false
      t.string    :gifted_to,             :limit => 200
      t.string    :gift_message,          :limit => 4000
      # Billing Address
      t.string    :billing_street,        :limit => 200,  :null => false
      t.string    :billing_city,          :limit => 200,  :null => false
      t.string    :billing_state,         :limit => 200,  :null => false
      t.string    :billing_postcode,      :limit => 25,   :null => false
      t.string    :billing_country,       :limit => 2,    :null => false # ISO 3166 alpha-2
      # Shipping Address
      t.string    :shipping_street,       :limit => 200
      t.string    :shipping_city,         :limit => 200
      t.string    :shipping_state,        :limit => 200
      t.string    :shipping_postcode,     :limit => 25
      t.string    :shipping_country,      :limit => 2 # ISO 3166 alpha-2

      t.string    :shipping_instructions, :limit => 4000

      t.boolean   :use_shipping_address,  :null => false, :default => false

      # Totals
      t.float     :actual_product_total,  :precision => 7,  :scale => 2,  :null => false
      t.float     :product_total,         :precision => 7,  :scale => 2,  :null => false
      t.float     :actual_shipping_total, :precision => 7,  :scale => 2,  :null => false
      t.float     :shipping_total,        :precision => 7,  :scale => 2,  :null => false
      t.float     :actual_total,          :precision => 7,  :scale => 2,  :null => false
      t.float     :total,                 :precision => 7,  :scale => 2,  :null => false
      t.float     :discount,              :precision => 7,  :scale => 2,  :null => false, :default => 0
      t.string    :currency,              :null => false, :limit => 4, :default => 'AUD'

      t.user_tracking(true)
      t.timestamps
    end

    add_column(:orders, :terms, :tsvector)
  end
end
