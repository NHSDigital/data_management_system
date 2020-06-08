require 'migration_helper'

# The DPIA_MODERATION -> CONTRACT_DRAFT transition requires the 2FA check
class ContractDraftRequiresYubikey < ActiveRecord::Migration[6.0]
  include MigrationHelper

  class Transition < ApplicationRecord
    self.table_name = 'workflow_transitions'
  end

  def change
    change_lookup Transition, 35, {}, { requires_yubikey: true }
  end
end
