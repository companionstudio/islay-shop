class CreatePromotionConditions < ActiveRecord::Migration
  def change
    create_table :promotion_conditions do |t|
      t.integer :promotion_id,  :null => false, :on_delete => :cascade
      t.string  :option,        :null => false, :limit => 50, :default => 'default'
      t.hstore  :config,        :null => false

      t.timestamps
    end
  end
end
