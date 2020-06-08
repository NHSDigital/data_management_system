class CreateNotificationTemplates < ActiveRecord::Migration[5.0]
  def change
    create_table :notification_templates do |t|
      t.string :name
      t.string :n_type
      t.text :content
      t.boolean :active

      t.timestamps null: false
    end
  end
end
