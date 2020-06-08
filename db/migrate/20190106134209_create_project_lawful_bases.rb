class CreateProjectLawfulBases < ActiveRecord::Migration[5.2]
  def change
    create_table :project_lawful_bases do |t|
      t.references :project, foreign_key: true
      t.references :lawful_basis, type: :string, foreign_key: true
    end
  end
end
