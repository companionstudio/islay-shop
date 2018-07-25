class AlterSkusWithSearchTerms < ActiveRecord::Migration[4.2]
  def up
    add_column(:skus, :terms, :tsvector)
  end

  def down
    remove_column(:skus, :terms)
  end
end
