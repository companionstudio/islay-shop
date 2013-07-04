class CreateServicePricePoints < ActiveRecord::Migration
  def up
    create_table :service_price_points do |t|
      t.integer :service_id,  :null => false, :on_delete => :cascade
      t.decimal :price,       :null => false, :precision => 14,  :scale => 7
      t.boolean :current,     :null => false, :default => false

      t.datetime :valid_from, :null => false
      t.datetime :valid_to,   :null => true

      t.user_tracking
    end

    execute(%{
      INSERT INTO service_price_points (service_id, price, current, valid_from, creator_id, updater_id)
      VALUES (
        (SELECT id FROM services WHERE key ='shipping' LIMIT 1),
        15,
        true,
        (SELECT created_at FROM services WHERE key = 'shipping' LIMIT 1),
        (SELECT id FROM users WHERE email = 'system@spookandpuff.com'),
        (SELECT id FROM users WHERE email = 'system@spookandpuff.com')
      )
    })
  end

  def down
    drop_table(:service_price_points)
  end
end
