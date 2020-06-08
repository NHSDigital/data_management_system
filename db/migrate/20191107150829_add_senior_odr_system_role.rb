class AddSeniorOdrSystemRole < ActiveRecord::Migration[6.0]
  include MigrationHelper

  def change
    add_lookup SystemRole, 4, sort: 4, name: 'ODR Senior Application Manager'
  end
end
