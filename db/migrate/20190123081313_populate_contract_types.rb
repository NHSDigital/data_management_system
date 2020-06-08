class PopulateContractTypes < ActiveRecord::Migration[5.2]
  include MigrationHelper
  
  class ContractType < ApplicationRecord
    attribute :value, :string
  end

  def change
    add_lookup ContractType, 1, value: 'Data Sharing Contract'
    add_lookup ContractType, 2, value: 'Data Sharing Licence'
    add_lookup ContractType, 3, value: 'Data Processing Agreement'
    add_lookup ContractType, 4, value: 'Non-Disclosure Agreement'
    add_lookup ContractType, 5, value: 'Direct Care'
  end
end
