# User model. Used by devise.
class User < ActiveRecord::Base
  class_attribute :special_users, default: {}

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :saml_authenticatable,     # Enables SAML SSO
         :database_authenticatable, # Enables storing of a hashed password in the DB
         :recoverable,              # Resets user password, and mails reset instructions
         :lockable,                 # Locks an account after n failed attempts
         :validatable,              # Adds basic validations to email and password
         :timeoutable               # Expires inactive sessions

  has_many :user_notifications, dependent: :destroy
  has_many :notifications, through: :user_notifications

  # Supports ODR application managers that are assigned to manage a `project`
  has_many :assigned_projects, class_name:  'Project',
                               foreign_key: :assigned_user_id,
                               inverse_of:  :assigned_user,
                               dependent:   :nullify

  has_many :grants, dependent: :destroy
  has_many :teams, -> { distinct.extending GrantedBy }, through: :grants
  has_many :projects, -> { distinct.extending GrantedBy }, through: :grants
  has_many :datasets, -> { distinct.extending GrantedBy }, through: :grants
  has_many :system_roles, through: :grants, source: :roleable, source_type: 'SystemRole'
  has_many :team_roles, through: :grants, source: :roleable, source_type: 'TeamRole'
  has_many :project_roles, through: :grants, source: :roleable, source_type: 'ProjectRole'
  has_many :dataset_roles, through: :grants, source: :roleable, source_type: 'DatasetRole'

  accepts_nested_attributes_for :teams
  attr_accessor :login
  belongs_to :z_user_status

  # TODO: How much do we care about or even need these in an NdrAuthenticate world?
  belongs_to :directorate, optional: true
  belongs_to :division,    optional: true

  scope :active,   -> { unlocked.joins(:z_user_status).merge(ZUserStatus.active) }
  scope :unlocked, -> { where(locked_at: nil) }
  scope :locked,   -> { where.not(locked_at: nil) }
  scope :deleted,  -> { where(z_user_status_id: ZUserStatus.find_by(name: 'Deleted').id) }
  scope :in_use,   -> { where.not(z_user_status_id: ZUserStatus.find_by(name: 'Deleted').id) }

  scope :administrators, -> { where(email: ADMIN_USER_EMAILS) }
  scope :odr_users, -> { where(email: ODR_USER_EMAILS) }

  scope :application_managers, lambda {
    where(id: joins(:grants).joins(:system_roles).
              merge(SystemRole.where(name: 'ODR Application Manager')))
  }

  scope :senior_application_managers, lambda {
    where(id: joins(:grants).joins(:system_roles).
              merge(SystemRole.where(name: 'ODR Senior Application Manager')))
  }

  scope :all_application_managers, lambda {
    where(id: joins(:grants).joins(:system_roles).
              merge(SystemRole.where('name ILIKE ?', '% Application Manager')))
  }

  scope :delegate_users, lambda {
    where(id: joins(:grants).joins(:team_roles).merge(TeamRole.delegates))
  }

  scope :applicants, lambda {
    where(id: joins(:grants).joins(:team_roles).merge(TeamRole.applicants))
  }

  validates :username,      uniqueness: { conditions: -> { where.not(username: nil) } }
  validates :first_name,    presence: true
  validates :last_name,     presence: true
  validates :email,         presence: true
  # validates :location,      presence: true
  # validates :z_user_status, presence: true

  validate :password_complexity # TODO: Can we use the configuration option on the Devise module?
  validate :ensure_teams_all_exist

  before_validation :set_default_z_user_status
  before_validation :set_default_password
  before_save :account_locked, if: :locked_at_changed?
  after_create :new_user_notification
  after_update :edit_user_notification

  # NOTE: Belt and braces. We're having to create accounts for non-PHE applicants because the
  # (current) architecture demands it. The users will never be able to access the system, so we'll
  # lock the accounts as a matter of course.
  before_save -> { self.locked_at = Time.zone.now if external? }

  # Allow for auditing/version tracking of User
  has_paper_trail ignore: %i[
    encrypted_password
    reset_password_token
    reset_password_sent_at
    remember_created_at
    current_sign_in_at
    current_sign_in_ip
    last_sign_in_ip
    failed_attempts
    locked_at
    session_index
  ]

  def current_ability
    @current_ability ||= self.class.module_parent::Ability.new(self)
  end

  delegate :can?, :cannot?, to: :current_ability

  alias_attribute :name, :username
  # https://blogs.msdn.microsoft.com/openspecification/2013/10/08/guids-and-endianness-endi-an-ne-ssinguid-or-idne-na-en-ssinguid/
  def guid
    return if object_guid.blank?

    object_guid.unpack1('m').
      unpack('V v v A*').
      pack('N n n A*').
      unpack('H8 H4 H4 H4 H12').
      join('-')
  end

  # Show the full name of a User
  def full_name
    [first_name, last_name].reject(&:blank?).join(' ').titleize
  end

  # Do not allow login for users who have been flagged as 'deleted'
  # Switched to only allow active users to login
  def active_for_authentication?
    # super && !flagged_as_deleted?
    super && flagged_as_active?
  end

  def flagged_as_deleted?
    ZUserStatus.find_by(name: 'Deleted').id == z_user_status_id
  end

  def flagged_as_active?
    ZUserStatus.find_by(name: 'Active').id == z_user_status_id
  end

  def teams?
    # TODO:
    teams.count.positive?
  end

  def login=(login)
    @login = login
  end

  def login
    @login || username || email
  end

  def internal?
    email&.downcase&.end_with?('@phe.gov.uk') || false
  end

  def external?
    !internal?
  end

  def project_senior_user?
    return unless projects
    projects.map { |pj| pj.owner.id }.include? id
  end

  def yubikey
    VALID_YUBIKEYS.key(username)
  end

  def administrator?
    ADMIN_USER_EMAILS.include?(email)
  end

  def odr?
    system_roles.include? SystemRole.fetch(:odr)
  end

  # This currently does _not_ return true for seniors
  def application_manager?
    return true if role?(SystemRole.fetch(:application_manager))
  end

  def senior_application_manager?
    return true if role?(SystemRole.fetch(:senior_application_manager))
  end

  def standard?
    !administrator? && !odr? && !application_manager? && !senior_application_manager?
  end

  def applicant?
    return true if role?(TeamRole.fetch(:mbis_applicant))
    return true if role?(TeamRole.fetch(:odr_applicant))
  end
  # def notifications
  #   Notification.where('admin_users = ? or odr_users = ? or user_id = ?',
  #                      administrator?, odr?, id)
  # end

  def cas_dataset_approver?
    return true if role?(DatasetRole.fetch(:approver))
  end

  def cas_access_approver?
    return true if role?(SystemRole.fetch(:cas_access_approver))
  end

  def cas_manager?
    return true if role?(SystemRole.fetch(:cas_manager))
  end
  def new_user_notification
    Notification.create!(title: 'New user added',
                         body: CONTENT_TEMPLATES['email_new_user']['body'] %
                               { full_name: full_name },
                         admin_users: true)
  end

  def edit_user_notification
    # Don't send a notification every time a user gets their password wrong
    if no_notification?
      # do nothing
    elsif unlocked?
      user_unlocked_notification
    else
      standard_update_notification
    end
  end

  def standard_update_notification
    Notification.create!(title: 'User details have been updated',
                         body: CONTENT_TEMPLATES['email_user_details_changed']['body'] %
                               { full_name: full_name },
                         admin_users: true)

  end

  def forgot_password_notification
    Notification.create!(title: 'User has forgotten password',
                         body: CONTENT_TEMPLATES['email_admin_forgotten_password']['body'] %
                              { full_name: full_name },
                         admin_users: true)
  end

  def wrong_password_notifiction
    Notification.create!(title: 'User has entered wrong password 3 times. Account is now locked',
                         body: CONTENT_TEMPLATES['email_admin_incorrect_password']['body'] %
                               { full_name: full_name },
                         admin_users: true)
  end

  def user_unlocked_notification
    Notification.create!(title: 'User has been unlocked',
                         body: CONTENT_TEMPLATES['email_user_details_changed']['body'] %
                               { full_name: full_name },
                         admin_users: true)
  end

  def self.senior_users
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions.to_hash).where(["lower(username) = :value OR lower(email) = :value",
                                       { value: login.downcase }]).first
    elsif conditions.key?(:username) || conditions.key?(:email)
      find_by(conditions.to_hash)
    end
  end

  def name_and_email
    full_name + ' - ' + email
  end

  def role?(role, at: nil)
    grants.detect do |grant|
      grant.roleable == role && (grant.team == at || grant.project == at || grant.dataset == at)
    end
  end

  # TODO: unit test
  def team_delegate_user?
    return if (grants.map(&:roleable) & TeamRole.delegates).empty?

    true
  end

  def system_user?
    return true if administrator?

    SystemRole.project_based.any? { |role| role?(role) }
  end

  private

  def set_default_z_user_status
    return if persisted?
    return if z_user_status

    self.z_user_status = ZUserStatus.find_by(name: 'Active')
  end

  # TODO: This should be deprecated once all authentication is migrated to NdrAuthenticate
  def set_default_password
    return if persisted?
    return if encrypted_password.present? || password.present?

    special = ['.', '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '-', '+', '=']

    required = []
    required.push ('A'..'Z').to_a.sample
    required.push ('a'..'z').to_a.sample
    required.push (0..9).to_a.sample
    required.push special.sample

    token  = Devise.friendly_token
    passwd = token.chars.concat(required).shuffle.join

    self.password_confirmation = self.password = passwd
  end

  def ensure_teams_all_exist
    return if teams.all?(&:persisted?)
    errors.add(:teams, 'must exist already')
  end

  def set_username
    self.username = (first_name + last_name).downcase
  end

  def account_locked
    return if locked_at.nil?
    self.z_user_status_id = ZUserStatus.find_by(name: 'Lockout').id
  end

  def password_complexity
    pattern = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*(_|[^\w])).+$/
    return unless password.present? && (password.size < 8 || !password.match(pattern))
    errors.add :password, 'Password must be 8 characters long and include at least one ' \
                          'lowercase letter, one uppercase letter, ' \
                          'one digit and 1 special character'
  end

  def no_notification?
    saved_change_to_session_index? || failed_login_only? || user_status_only? || save_only?
  end

  def failed_login_only?
    saved_changes.keys.reject { |k| k.eql?('updated_at') } == %w(failed_attempts)
  end

  def unlocked?
    return false if saved_changes.keys.exclude? 'z_user_status_id'
    # retain z_user_status change order
    status_update = saved_changes['z_user_status_id'].map { |s| ZUserStatus.find(s).name }
    status_update == %w(Lockout Active)
  end

  def user_status_only?
    saved_changes.keys.include? 'locked_at'
  end

  def save_only?
    saved_changes.empty?
  end

  class << self
    def search(params)
      filters = []
      %i[first_name last_name username email].each do |field|
        filters << field_filter(field, params[:name])
      end

      filters.compact!
      scope = all
      filters.each_with_index do |filter, i|
        scope = i.zero? ? scope.where(filter) : scope.or(where(filter))
      end

      scope
    end

    private

    def name_filter(text)
      arel_table[:name].matches("%#{text.strip}%") if text.present?
    end

    def field_filter(field, text)
      arel_table[field].matches("%#{text.strip}%") if text.present?
    end
  end
end
