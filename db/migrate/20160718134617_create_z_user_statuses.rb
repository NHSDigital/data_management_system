class CreateZUserStatuses < ActiveRecord::Migration[5.0]
  def change
    create_table :z_user_statuses do |t|
      t.string :name

      t.timestamps
    end
  end
end
