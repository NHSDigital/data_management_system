# plan.io 19589
class MigrateProjectClassificationsToProjectLevelOfIdentifiability < ActiveRecord::Migration[6.0]
  def up
    transaction do
      Project.all.each do |project|
        next if project.classifications.blank?

        raise 'Not expecting Project to have multiple classifications' if
          project.classifications.size > 1

        project.level_of_identifiability = lookup[project.classifications.first.name]
        project.save(validate: false)
      end
    end
  end

  def down
    transaction do
      Project.all.each do |project|
        next if project.classifications.blank?

        raise 'Not expecting Project to have multiple classifications' if
          project.classifications.size > 1

        project.level_of_identifiability = nil
        # production projects can be invalid
        project.save(validate: false)
      end
    end
  end

  def lookup
    {
      'identifiable' => 'Personally Identifiable',
      'potentially identifiable' => 'De-personalised',
      'Anonymised' => 'Anonymous'
    }
  end
end
