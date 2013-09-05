# This migration comes from islay_engine (originally 20120823010554)
class CreatePages < ActiveRecord::Migration
  def change
    create_table :pages do |t|
      t.string :slug,     :null => false, :limit => 50
      t.hstore :entries,  :null => true

      t.user_tracking
      t.timestamps
    end
  end
end
