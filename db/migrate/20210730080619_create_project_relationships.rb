class CreateProjectRelationships < ActiveRecord::Migration[6.0]
  def change
    create_table :project_relationships do |t|
      t.references :left_project,  null: false, foreign_key: { to_table: :projects }
      t.references :right_project, null: false, foreign_key: { to_table: :projects }

      t.timestamps
    end

    # Guard against inverse pairs
    add_index :project_relationships,
              'LEAST(left_project_id, right_project_id), GREATEST(left_project_id, right_project_id)',
              name: :index_project_relationships_on_left_project_id_right_project_id,
              unique: true

    # Guard against self-referential relationships
    add_check_constraint :project_relationships, 'left_project_id != right_project_id'
  end

  private

  # Backport from Rails 6.1.x
  def add_check_constraint(table_name, expression)
    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          ALTER TABLE #{table_name}
          ADD CONSTRAINT #{check_constraint_name(table_name, expression)}
          CHECK (#{expression});
        SQL
      end

      dir.down do
        execute <<~SQL.squish
          ALTER TABLE #{table_name}
          DROP CONSTRAINT IF EXISTS #{check_constraint_name(table_name, expression)};
        SQL
      end
    end
  end

  # Backport from Rails 6.1.x
  def check_constraint_name(table_name, expression)
    identifier        = "#{table_name}_#{expression}_chk"
    hashed_identifier = Digest::SHA256.hexdigest(identifier).first(10)

    "chk_rails_#{hashed_identifier}"
  end
end
