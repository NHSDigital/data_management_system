class DatasetRole < ApplicationRecord
  has_many :grants, as: :roleable
  has_many :users, -> { distinct }, through: :grants

  def self.fetch(key)
    return key if key.is_a?(self)

    @dataset_roles ||= {
      approver: unscoped.where(name: 'Approver').first!
    }

    @dataset_roles.fetch(key)
  end
end
