# 20191125 This migration has been added manually to get LIVE up to date
class PopulatePheOrganisation < ActiveRecord::Migration[5.2]
  def up
    return if Rails.env.test?
    return if Organisation.where(name: 'Public Health England').count.positive?
    
    Rake::Task['organisation:migrate'].invoke
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
