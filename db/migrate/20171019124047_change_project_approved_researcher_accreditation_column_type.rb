class ChangeProjectApprovedResearcherAccreditationColumnType < ActiveRecord::Migration[5.0]
  def up
    remove_column :projects, :approved_research_accreditation
    add_column :projects, :approved_research_accreditation, :boolean
  end

  def down
    remove_column :projects, :approved_research_accreditation
    add_column :projects, :approved_research_accreditation, :string
  end
end
