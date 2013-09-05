# This migration comes from islay_engine (originally 20120531102912)
class CreatePeople < ActiveRecord::Migration
  def change
    create_table :people do |t|
      t.string :name,   :null => false, :limit => 200
      t.string :email,  :null => false, :limit => 200

      t.timestamps
    end
  end
end
