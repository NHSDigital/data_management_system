class RenameOdrProjectFields < ActiveRecord::Migration[5.2]
  def change
    rename_column :projects, :test_drr_project_summary, :project_summary
    rename_column :projects, :test_drr_why_data_required, :why_data_required
    rename_column :projects, :test_drr_public_benefit, :public_benefit
  end
end
