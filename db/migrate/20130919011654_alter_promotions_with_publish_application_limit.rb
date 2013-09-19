class AlterPromotionsWithPublishApplicationLimit < ActiveRecord::Migration
  def up
    add_column(:promotions, :publish_application_limit, :boolean, :default => true)
  end

  def down
    remove_column(:promotions, :publish_application_limit)
  end
end
