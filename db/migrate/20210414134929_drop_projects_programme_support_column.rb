# Plan.io 25796 - remove programme_support column after data has been moved to programme_support_id
class DropProjectsProgrammeSupportColumn < ActiveRecord::Migration[6.0]
  def change
    remove_column :projects, :programme_support, :boolean, default: false
  end
end
