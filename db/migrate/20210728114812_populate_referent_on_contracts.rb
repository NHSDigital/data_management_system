class PopulateReferentOnContracts < ActiveRecord::Migration[6.0]
  class Contract < ApplicationRecord; end

  def up
    Contract.find_each do |contract|
      contract.update!(referent_type: 'Project', referent_id: contract.project_id)
    end
  end

  # no-op
  def down; end
end
