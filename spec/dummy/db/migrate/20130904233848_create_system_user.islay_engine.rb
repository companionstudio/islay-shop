# This migration comes from islay_engine (originally 20130704044413)
class CreateSystemUser < ActiveRecord::Migration
  def up
    add_column(:users, :immutable, :boolean, :null => false, :default => false)
    execute(%{
      INSERT INTO users (name, email, encrypted_password, immutable, created_at, updated_at)
      VALUES ('system', 'system@spookandpuff.com', 'password', true, NOW(), NOW())
    })
  end

  def down
    remove_column(:users, :immutable)
    execute("DELETE FROM users WHERE email = 'system@spookandpuff.com'")
  end
end
