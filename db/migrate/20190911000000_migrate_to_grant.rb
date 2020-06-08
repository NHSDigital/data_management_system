# 20191125 This migration has been added manually to get LIVE up to date
class MigrateToGrant < ActiveRecord::Migration[6.0]
  def up
    return if Rails.env.test?
    return if Grant.count.positive?
    
    Rake::Task['grants:migrate'].invoke
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
