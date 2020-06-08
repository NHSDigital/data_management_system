class RenameProjectAdditionalInformation < ActiveRecord::Migration[5.0]
  def change
    rename_column :projects, :additional_information, :cohort_inclusion_exclusion_criteria
  end
end
