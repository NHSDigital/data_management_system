class AddSystemRoles < ActiveRecord::Migration[6.0]
  include MigrationHelper
  def change
    add_lookup SystemRole, 1, sort: 1, name: 'Developer'
    add_lookup SystemRole, 2, sort: 2, name: 'ODR'
    add_lookup SystemRole, 3, sort: 3, name: 'ODR Application Manager'
  end
end
