class PopulateNewProjectTypesTable < ActiveRecord::Migration[5.2]
  include MigrationHelper

  class ProjectType < ApplicationRecord
  end

  def change
    ProjectType.reset_column_information

    add_lookup ProjectType, 1, name: 'Project'
    add_lookup ProjectType, 2, name: 'EOI'
    add_lookup ProjectType, 3, name: 'Application'
  end
end
