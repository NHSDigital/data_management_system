# 20191125 This migration has been added manually to get LIVE up to date
class MigrateToProjectStates < ActiveRecord::Migration[5.2]
  def up
    return if Rails.env.test?
    return if Project.count.zero?
    
    Rake::Task['workflow:migrate'].invoke
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
