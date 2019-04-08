class OrderLog < ActiveRecord::Base
  belongs_to :order

  track_user_edits

  def url_params
    [order]
  end

  # Creates a select statement with calculated fields to be used when
  # summarising the logs
  #
  # @return ActiveRecord::Relation
  def self.summary
    select(%{
      succeeded, action, notes, created_at,
      CASE
        WHEN updater_id IS NULL then 'Customer'
        ELSE (SELECT name FROM users WHERE id = updater_id)
      END AS updater_name
    }).order('created_at DESC')
  end
end
