class RemoveNotificationTemplate < ActiveRecord::Migration[5.0]
  def change
    drop_table :notification_templates, force: :cascade
  end
end
