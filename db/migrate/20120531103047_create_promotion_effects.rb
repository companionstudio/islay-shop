class CreatePromotionEffects < ActiveRecord::Migration
  def change
    create_table :promotion_effects do |t|
      t.integer :promotion_id,  :null => false, :on_delete => :cascade
      t.string  :type,          :null => false, :default => 'PromotionEffect'
      t.hstore  :config,        :null => false

      t.timestamps
    end
  end
end
