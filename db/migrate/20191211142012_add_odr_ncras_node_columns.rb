class AddOdrNcrasNodeColumns < ActiveRecord::Migration[6.0]
  def change
    add_column :nodes, :restrictions_recommendations, :text
    add_column :nodes, :notes, :text
  end
end
