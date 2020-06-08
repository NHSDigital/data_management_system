# Defines DataSource associations and validations
class DataSource < ApplicationRecord
  has_many :teams
  has_many :data_source_items, dependent: :destroy

  accepts_nested_attributes_for :data_source_items
end
