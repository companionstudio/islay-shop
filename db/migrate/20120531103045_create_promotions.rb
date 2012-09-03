class CreatePromotions < ActiveRecord::Migration
  def change
    create_table :promotions do |t|
      t.string    :name,        :null => false, :limit => 200
      t.string    :description, :null => true, :limit => 4000
      t.boolean   :active,      :null => false, :default => false

      t.timestamp :start_at,    :null => false
      t.timestamp :end_at,      :null => false

      t.timestamps
    end

    add_column(:promotions, :terms, :tsvector)
  end
end
