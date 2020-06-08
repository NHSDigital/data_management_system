class TeamRole < ApplicationRecord
  has_many :grants, as: :roleable
  has_many :users, -> { distinct }, through: :grants
  
  scope :read_only, -> { where(name: 'Read Only') }
  scope :delegates, -> { where(name: 'MBIS Delegate') }
  scope :applicants, -> { where(name: ['MBIS Applicant', 'ODR Applicant']) }

  def self.fetch(key)
    return key if key.is_a?(self)

    @team_roles ||= {
      read_only:       unscoped.where(name: 'Read Only').first!,
      mbis_applicant:  unscoped.where(name: 'MBIS Applicant').first!,
      mbis_delegate:   unscoped.where(name: 'MBIS Delegate').first!,
      odr_applicant:   unscoped.where(name: 'ODR Applicant').first!,
      dataset_manager: unscoped.where(name: 'Dataset Manager').first!
    }

    @team_roles.fetch(key)
  end
end
