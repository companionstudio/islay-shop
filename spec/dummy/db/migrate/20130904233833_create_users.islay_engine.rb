# This migration comes from islay_engine (originally 20120515043405)
class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string    :name,                    :null => false, :limit => 200
      t.string    :email,                   :null => false, :limit => 200, :index => :unique
      t.string    :encrypted_password,      :null => false, :limit => 200
      t.string    :reset_password_token,    :null => true,  :limit => 200, :index => :unique
      t.datetime  :reset_password_sent_at,  :null => true

      t.timestamps
    end
  end
end
