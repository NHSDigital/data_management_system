# plan.io #28576
class AddManagingOrganisationIdToDataset < ActiveRecord::Migration[6.0]
  def change
    add_column :datasets, :managing_organisation_id, :integer
  end
end
