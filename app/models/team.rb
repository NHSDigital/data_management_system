# Team associations and validations
class Team < ActiveRecord::Base
  belongs_to :z_team_status
  belongs_to :organisation
  belongs_to :directorate, optional: true
  belongs_to :division,    optional: true

  has_many :projects

  has_many :grants, foreign_key: :team_id, dependent: :destroy
  has_many :users, -> { extending(GrantedBy).distinct }, through: :grants
  has_many :datasets, dependent: :nullify
  has_many :addresses, as: :addressable
  accepts_nested_attributes_for :addresses, reject_if: :all_blank,
                                allow_destroy: true, update_only: :true
  after_update :send_notification

  validates :name, presence: true,
                   uniqueness: { scope: :organisation_id,
                                 message: 'One occurrence per Organisation' }

  validates :z_team_status_id, presence: true

  delegate :name, to: :z_team_status, prefix: true # z_team_status_name
  delegate :senior_members, to: :members

  scope :all_except, ->(team) { where.not(id: team) }
  scope :active, -> { where.not(z_team_status: ZTeamStatus.where(name: 'Deleted').first) }

  # Allow for auditing/version tracking of Team
  has_paper_trail

  # Filter membership dropdown to
  # active Users who are not already
  # a team member - exclude admin and odr users
  def active_users_who_are_not_team_members
    member_ids = users.pluck(&:id)
    not_in_team = User.in_use.reject do |user|
      member_ids.include?(user.id) || user.administrator? || user.odr?
    end
    not_in_team - Grant.systems.map(&:user)
  end

  # Conditional prompt for team
  # membership dropdown
  def team_membership_prompt
    if active_users_who_are_not_team_members.count.zero?
      'All active users are already Team members...'
    else
      'Pick a Team member...'
    end
  end

  def disable_team_membership_dropdown?
    active_users_who_are_not_team_members.count.zero?
  end

  def send_notification
    if z_team_status_name == 'Active' &&
       z_team_status_id_before_last_save == ZTeamStatus.where(name: 'New').first.id
      new_team_notification
    elsif z_team_status_id_before_last_save != ZTeamStatus.where(name: 'New').first.id && !saved_changes.nil?
      updates = []
      # TODO when any of these are deleted this will fail as it can't find old id(s)
      saved_changes.each do | k, v |
        next if ['updated_at'].include? k
        case k
        when 'z_team_status_id'
          updates << "Status changed from '#{ZTeamStatus.find(v[0]).name}' to '#{ZTeamStatus.find(v[1]).name}'"
        when 'delegate_approver'
          updates << "Delegate approver changed from '#{User.find_by_id(v[0])&.full_name}' to '#{User.find(v[1]).full_name}'"
        when 'division_id'
          updates << "Division changed from '#{Division.find(v[0]).name}' to '#{Division.find(v[1]).name}'"
        when 'directorate_id'
          updates << "Directorate changed from '#{Directorate.find(v[0]).name}' to '#{Directorate.find(v[1]).name}'"
        else
          updates << "#{k} changed from '#{v[0]}' to '#{v[1]}'"
        end
      end
      edit_team_notification(updates.join("\n\n")) if !updates.empty?
    end
  end

  def new_team_notification
    Notification.create!(title: 'New team created in MBIS : ' + name,
                         body: CONTENT_TEMPLATES['email_admin_and_odr_new_team']['body'] %
                               { team_name: name, team_address: location,
                                 team_postcode: postcode, team_status: z_team_status_name,
                                 team_telephone: telephone,
                                 team_members: users.collect(&:full_name).join(', '),
                                 team_link: '/projects/' + id.to_s,
                                 mbis_contact_tel: CONTENT_TEMPLATES['mbis_admin_phone_number'] },
                         admin_users: true,
                         odr_users: false,
                         senior_users: true,
                         team_id: id)
  end

  def edit_team_notification(team_changes)
    Notification.create!(title: "Team '#{name}' edited : ",
                         body: CONTENT_TEMPLATES['email_admin_and_odr_edit_team']['body'] %
                               { team_name: name,
                                 team_changes: team_changes,
                                 mbis_contact_number: CONTENT_TEMPLATES['mbis_admin_phone_number'],
                                 team_link: '/projects/' + id.to_s },
                         admin_users: true,
                         team_id: id)
  end

  # TODO: Move to Grant
  def delegate_not_admin_or_odr
    delegate_users.each do |delegate_user|
      if !delegate_user.nil? && (delegate_user.administrator? || delegate_user.odr?)
        errors.add(:delegate_approver, 'Delegate approver cannot be an Administrator or ODR user')
      end
    end
  end

  # Scope chaining not quite right
  def delegate_users
    users.joins(:grants).where(grants: { roleable: TeamRole.fetch(:mbis_delegate) } )
  end

  class << self
    def search(scope, params)      
      team_filter = name_filter(params[:name])
      org_filter  = organisation_filter(params[:name])
      scope = scope.joins(:organisation)

      scope.where(team_filter).or(scope.where(org_filter))
    end

    private

    def name_filter(text)
      arel_table[:name].matches("%#{text.strip}%") if text.present?
    end

    def organisation_filter(text)
      Organisation.arel_table[:name].matches("%#{text.strip}%") if text.present?
    end
  end
end
