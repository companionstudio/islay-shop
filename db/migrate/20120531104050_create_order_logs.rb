class CreateOrderLogs < ActiveRecord::Migration
  def change
    create_table :order_logs do |t|
      t.integer   :order_id,    :null => false, :on_delete => :cascade
      t.boolean   :succeeded,  :null => false, :default => true
      t.string    :action,      :null => false, :limit => 20
      t.string    :notes,       :limit => 2000

      t.user_tracking(true)
      t.timestamps
    end
  end
end
