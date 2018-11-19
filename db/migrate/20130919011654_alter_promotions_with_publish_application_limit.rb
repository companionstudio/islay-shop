class AlterPromotionsWithPublishApplicationLimit < ActiveRecord::Migration[4.2]
  def up
    add_column(:promotions, :publish_application_limit, :boolean, :default => true)
  end

  def down
    remove_column(:promotions, :publish_application_limit)
  end
end
