class AddTeamRoles < ActiveRecord::Migration[6.0]
  include MigrationHelper
  def change
    add_lookup TeamRole, 1, sort: 1, name: 'Read Only'
    add_lookup TeamRole, 2, sort: 2, name: 'MBIS Applicant'
    add_lookup TeamRole, 3, sort: 3, name: 'MBIS Delegate'
    add_lookup TeamRole, 4, sort: 4, name: 'ODR Applicant'
    add_lookup TeamRole, 5, sort: 5, name: 'Dataset Manager'
  end
end
