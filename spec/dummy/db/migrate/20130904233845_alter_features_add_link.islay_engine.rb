# This migration comes from islay_engine (originally 20121019075010)
class AlterFeaturesAddLink < ActiveRecord::Migration
  def up
    add_column(:features, :link_url, :string)
    add_column(:features, :link_title, :string)
  end

  def down
    remove_column(:features, :link_url)
    remove_column(:features, :link_title)
  end
end
