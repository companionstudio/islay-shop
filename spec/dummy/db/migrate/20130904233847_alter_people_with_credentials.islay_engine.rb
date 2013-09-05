# This migration comes from islay_engine (originally 20130225005725)
class AlterPeopleWithCredentials < ActiveRecord::Migration
  def up
    add_column(:people, :encrypted_password,      :string,    :null => false, :limit => 200)
    add_column(:people, :reset_password_token,    :string,    :null => true,  :limit => 200, :index => :unique)
    add_column(:people, :reset_password_sent_at,  :datetime,  :null => true)
  end

  def down
    remove_column(:people, :encrypted_password)
    remove_column(:people, :reset_password_token)
    remove_column(:people, :reset_password_sent_at)
  end
end
