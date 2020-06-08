class ZUserStatus < ApplicationRecord
  has_many :users

  scope :active, -> { where(name: 'Active') }
end
