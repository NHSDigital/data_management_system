class PopulateProgrammeSupports < ActiveRecord::Migration[6.0]
  include MigrationHelper

  class ProgrammeSupport < ApplicationRecord
    attribute :value, :string
  end

  def change
    add_lookup ProgrammeSupport, 1, value: 'Yes'
    add_lookup ProgrammeSupport, 2, value: 'No'
    add_lookup ProgrammeSupport, 3, value: 'Not applicable'
  end
end
