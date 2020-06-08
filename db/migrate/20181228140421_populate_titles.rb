class PopulateTitles < ActiveRecord::Migration[5.2]
  include MigrationHelper
  
  class Title < ApplicationRecord
    attribute :value, :string
  end

  def change
    add_lookup Title, 1, value: 'Dame'
    add_lookup Title, 2, value: 'Dr'
    add_lookup Title, 3, value: 'Miss'
    add_lookup Title, 4, value: 'Mr'
    add_lookup Title, 5, value: 'Mrs'
    add_lookup Title, 6, value: 'Ms'
    add_lookup Title, 7, value: 'Professor'
    add_lookup Title, 8, value: 'Sir'
  end
end
