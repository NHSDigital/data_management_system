class AddSortToEnumerationValue < ActiveRecord::Migration[5.2]
  def change
    add_column :enumeration_values, :sort, :integer
  end
end
