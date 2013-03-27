class CreateManufacturers < ActiveRecord::Migration
  def up
    create_table :manufacturers do |t|
      t.integer     :position,            :null => false, :limit => 3, :default => 1
      t.string      :name,                :null => false, :limit => 200, :index => {:unique => true}
      t.string      :slug,                :null => false, :limit => 200, :index => {:unique => true}
      t.string      :description,         :null => true,  :limit => 4000
      t.hstore      :metadata,            :null => true

      t.publishing
      t.user_tracking
      t.timestamps
    end

    add_column(:manufacturers, :terms, :tsvector)
  end

  def down
    drop_table(:manufacturers)
  end
end

