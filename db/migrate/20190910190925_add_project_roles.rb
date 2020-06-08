class AddProjectRoles < ActiveRecord::Migration[6.0]
  include MigrationHelper
  def change
    add_lookup ProjectRole, 1, sort: 1, name: 'Read Only'
    add_lookup ProjectRole, 2, sort: 2, name: 'Owner'    
    add_lookup ProjectRole, 3, sort: 3, name: 'Contributor'
  end
end
