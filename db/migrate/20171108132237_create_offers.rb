class CreateOffers < ActiveRecord::Migration
  def change
    create_table :offers do |t|
      t.string    :name,                    :null => false, :limit => 200, :unique => true
      t.string    :slug,                    :null => false, :limit => 200, :unique => true
      t.string    :status,                  :null => false, :limit => 64, :default => 'active'
      t.string    :description,             :limit => 4000
      t.decimal   :price,                   :null => false, :precision => 14,  :scale => 7
      t.hstore    :metadata,                :null => true

      t.timestamp :open_at
      t.timestamp :close_at
      t.timestamp :ship_at

      t.user_tracking(true)
      t.publishing
      t.timestamps
    end

    create_table :offer_items do |t|
      t.integer :offer_id,        :null => false
      t.integer :sku_id,          :null => false
      t.integer :quantity,        :null => false, :limit => 3, :default => 1

      t.user_tracking(true)
      t.timestamps
    end

    create_table :offer_orders do |t|
      t.integer :offer_id,        :null => false
      t.integer :order_id,        :null => false

      t.user_tracking(true)
      t.timestamps
    end
  end
end
