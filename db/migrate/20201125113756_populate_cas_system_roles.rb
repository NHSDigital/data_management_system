class PopulateCasSystemRoles < ActiveRecord::Migration[6.0]
  include MigrationHelper
  def change
    add_lookup SystemRole, 7, sort: 7, name: 'CAS Dataset Approver'
    add_lookup SystemRole, 8, sort: 8, name: 'CAS Access Approver'
    add_lookup SystemRole, 9, sort: 9, name: 'CAS Manager'
  end
end