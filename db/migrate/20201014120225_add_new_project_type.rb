class AddNewProjectType < ActiveRecord::Migration[6.0]
  include MigrationHelper

  class ProjectType < ApplicationRecord
  end

  def change
    ProjectType.reset_column_information

    add_lookup ProjectType, 4, name: 'CAS'
  end
end
