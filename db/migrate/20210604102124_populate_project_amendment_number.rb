# legacy ODR amendment references are inconsistent. grep the A number from the references
class PopulateProjectAmendmentNumber < ActiveRecord::Migration[6.0]
  def up
    Project.transaction do
      Project.odr_projects.each do |app|
        next if app.project_amendments.empty?

        amendment_refs = app.project_amendments.each_with_object([]) do |amendment, references|
          next if amendment.reference.nil?

          matches = amendment.reference.scan /A(\d+)/
          raise 'reference should only contain one A value' if matches.size > 1
          next if matches.empty?

          references << matches[0].first.to_i
        end
        app.update(amendment_number: amendment_refs.max)
      end
    end
  end

  def down
    Project.odr_projects.update_all(amendment_number: 0)
  end
end
