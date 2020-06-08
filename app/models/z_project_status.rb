class ZProjectStatus < ApplicationRecord
  has_many :projects

  scope :awaiting_sign_off, -> { where(name: ['New', 'Delegate Approval', 'Pending']) }
end
