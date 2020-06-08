class CreateProjectAttachments < ActiveRecord::Migration[5.0]
  def change
    create_table :project_attachments do |t|
      t.references :project, foreign_key: true
      t.string :name
      t.string :comments
      #t.binary :attachment

      t.timestamps
    end
  end
end
