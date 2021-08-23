class AddClosureReasons202108 < ActiveRecord::Migration[6.0]
  include MigrationHelper

  class ClosureReason < ApplicationRecord; end

  def change
    add_lookup ClosureReason, 13, { value: 'Letter of Support supplied' }
    add_lookup ClosureReason, 14, { value: 'Indicative costs supplied' }
  end
end
