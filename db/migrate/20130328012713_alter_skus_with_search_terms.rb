class AlterSkusWithSearchTerms < ActiveRecord::Migration
  def up
    add_column(:skus, :terms, :tsvector)
  end

  def down
    remove_column(:skus, :terms)
  end
end
