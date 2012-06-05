class CreatePromotions < ActiveRecord::Migration
  def change
    create_table :promotions do |t|
      t.string    :name,        :null => false, :limit => 200

      t.timestamp :start_at,    :null => false
      t.timestamp :end_at,      :null => false

      t.timestamps
    end
  end
end
