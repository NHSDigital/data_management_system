class PopulateSecurityAssurances < ActiveRecord::Migration[5.2]
  include MigrationHelper
  
  class SecurityAssurance < ApplicationRecord
    attribute :value, :string
  end

  def change
    add_lookup SecurityAssurance, 1, value: 'ISO 27001'
    add_lookup SecurityAssurance, 2, value: 'Data Security and Protection Toolkit'
    add_lookup SecurityAssurance, 3, value: 'Project specific System Level Security Policy'
  end
end
