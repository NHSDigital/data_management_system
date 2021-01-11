# CAS transitions require the 2FA check
class ChangeCasTransitionRequiresYubikey < ActiveRecord::Migration[6.0]
  include MigrationHelper

  class Transition < ApplicationRecord
    self.table_name = 'workflow_transitions'
  end

  def change
    change_lookup Transition, 79, {}, { requires_yubikey: true }
  end
end
