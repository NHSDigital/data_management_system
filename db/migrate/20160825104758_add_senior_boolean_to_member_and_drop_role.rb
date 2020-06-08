class AddSeniorBooleanToMemberAndDropRole < ActiveRecord::Migration[5.0]
  def change
    drop_table :users_roles
    drop_table :roles
    remove_column :memberships, :role
    add_column :memberships, :senior, :boolean
    add_column :project_memberships, :senior, :boolean
  end
end
