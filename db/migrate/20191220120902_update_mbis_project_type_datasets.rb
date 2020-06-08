class UpdateMbisProjectTypeDatasets < ActiveRecord::Migration[6.0]
  def up
    return if Rails.env.test?

    ProjectTypeDataset.all.each do |ptd|
      ptd.destroy if datasets.include? ptd.dataset.name
    end
    ProjectTypeDataset.create!(project_type: ProjectType.find_by(name: 'Project'),
                               dataset: Dataset.table_spec.find_by(name: 'MBIS'))
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def datasets
    ['Births Gold Standard', 'Death Transaction', 'Deaths Gold Standard', 'Birth Transaction']
  end
end
