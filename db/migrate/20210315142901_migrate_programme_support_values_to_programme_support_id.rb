# plan.io 22212
# Change comment: Second attempt at migrating programme_support data to lookup programme_support_id
# originally accidentally added a where.not rather than a where. Having to use Raw SQL to get around
# associations added in original commit
class MigrateProgrammeSupportValuesToProgrammeSupportId < ActiveRecord::Migration[6.0]
  def up
    transaction do
      sql = <<-SQL
        UPDATE PROJECTS
        SET PROGRAMME_SUPPORT_ID = (SELECT ID FROM programme_supports WHERE VALUE = 'No')
        WHERE PROGRAMME_SUPPORT = 'false'
        AND PROJECT_TYPE_ID = ( SELECT ID FROM PROJECT_TYPES WHERE NAME = 'Application');
      SQL
      ActiveRecord::Base.connection.execute(sql)

      sql = <<-SQL
        UPDATE PROJECTS
        SET PROGRAMME_SUPPORT_ID = (SELECT ID FROM programme_supports WHERE VALUE = 'Yes')
        WHERE PROGRAMME_SUPPORT = 'true'
        AND PROJECT_TYPE_ID = ( SELECT ID FROM PROJECT_TYPES WHERE NAME = 'Application');
      SQL
      ActiveRecord::Base.connection.execute(sql)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
