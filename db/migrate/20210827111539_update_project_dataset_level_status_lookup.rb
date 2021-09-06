# rename ProjectDatasetLevelStatus lookup description from expired to closed
class UpdateProjectDatasetLevelStatusLookup < ActiveRecord::Migration[6.0]
  include MigrationHelper
  def change
    id = Lookups::ProjectDatasetLevelStatus.find_by(value: '5').id
    change_lookup Lookups::ProjectDatasetLevelStatus, id, { description: 'Expired' }, { description: 'Closed' }
  end
end
