# plan.io 22212
# Change comment:  Migrate programme_support data to lookup programme_support_id
class MigrateProgrammeSupportToLookupField < ActiveRecord::Migration[6.0]
  def up
    transaction do
      Project.of_type_application.where.not('programme_support = true').
        update_all(programme_support_id: Lookups::ProgrammeSupport.find_by(value: 'Yes').id)
      Project.of_type_application.where.not('programme_support = false').
        update_all(programme_support_id: Lookups::ProgrammeSupport.find_by(value: 'No').id)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
