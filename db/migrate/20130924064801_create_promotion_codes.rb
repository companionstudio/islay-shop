class CreatePromotionCodes < ActiveRecord::Migration[4.2]
  def change
    create_table :promotion_codes do |t|
      t.integer   :promotion_condition_id,  :null => false, :on_delete => :cascade
      t.string    :code,                    :null => false, :limit => 200, :unique => true
      t.timestamp :redeemed_at,             :null => true
      t.integer   :order_id,                :null => true
      t.timestamps
    end
  end
end

