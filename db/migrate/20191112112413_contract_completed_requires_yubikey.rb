# The CONTRACT_DRAFT -> CONTRACT_COMPLETED transition requires the 2FA check
class ContractCompletedRequiresYubikey < ActiveRecord::Migration[6.0]
  include MigrationHelper

  class Transition < ApplicationRecord
    self.table_name = 'workflow_transitions'
  end

  def change
    change_lookup Transition, 37, {}, { requires_yubikey: true }
  end
end
