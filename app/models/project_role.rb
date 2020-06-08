class ProjectRole < ApplicationRecord
  has_many :grants, as: :roleable
  has_many :users, -> { distinct }, through: :grants
  
  scope :read_only, -> { where(name: 'Read Only') }
  scope :owner, -> { where(name: 'Owner') }
  scope :grantable_by_owner, -> { where(name: ['Contributor', 'Read Only']) }
  scope :can_edit, -> { where(name: %w[Owner Contributor]) }
  scope :contributors, -> { where(name: %w[Contributor]) }

  def self.fetch(key)
    return key if key.is_a?(self)

    @project_roles ||= {
      read_only:   unscoped.where(name: 'Read Only').first!,
      owner:       unscoped.where(name: 'Owner').first!,
      contributor: unscoped.where(name: 'Contributor').first!
    }

    @project_roles.fetch(key)
  end
end
