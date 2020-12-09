class SystemRole < ApplicationRecord
  has_many :grants, as: :roleable
  has_many :users, -> { distinct }, through: :grants

  scope :project_based, -> { where.not(name: 'Dataset Viewer') }
  scope :cas_manager_and_access_approvers, -> { where(name: ['CAS Manager', 'CAS Access Approver']) }

  def self.fetch(key)
    return key if key.is_a?(self)

    @system_roles ||= {
      odr:                        unscoped.where(name: 'ODR').first!,
      application_manager:        unscoped.where(name: 'ODR Application Manager').first!,
      senior_application_manager: unscoped.where(name: 'ODR Senior Application Manager').first!,
      developer:                  unscoped.where(name: 'Developer').first!,
      dataset_viewer:             unscoped.where(name: 'Dataset Viewer').first!,
      dataset_viewer_analyst:     unscoped.where(name: 'Dataset Viewer Analyst').first!,
      cas_access_approver:        unscoped.where(name: 'CAS Access Approver').first!,
      cas_manager:                unscoped.where(name: 'CAS Manager').first!
    }

    @system_roles.fetch(key)
  end
end
