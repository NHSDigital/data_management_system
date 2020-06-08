class CreateProjectComments < ActiveRecord::Migration[5.0]
  def change
    create_table :project_comments do |t|
      t.references :project, foreign_key: true
      t.references :user, foreign_key: true
      t.string :user_role
      t.string :comment_type
      t.text :comment
      t.references :project_data_source_item, foreign_key: true

      t.timestamps
    end
  end
end
