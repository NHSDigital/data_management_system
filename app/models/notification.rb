# Logic assigning Notifcations to Users
# based on User permissions/roles
# The Notifciation table is the master 'notification' - there is then a UserNotifications table for specific users
# The Notification table flags the 'type' of user the message should go to eg admin, project member, odr.
# The UserNotifciations are generated based on these flags of type of user
class Notification < ActiveRecord::Base
  scope :admin_users, -> { where admin_users: true }
  scope :odr_users, -> { where odr_users: true }
  scope :senior_users, -> { where senior_users: true }
  scope :by_title, ->(title) { where title: title }
  # scope :active, -> { where.not(status: 'deleted') }
  # scope :deleted, -> { where(status: 'deleted') }

  has_many :user_notifications, dependent: :destroy
  has_many :users, through: :user_notifications
  belongs_to :team, optional: true
  belongs_to :project, optional: true
  after_create :create_user_notifications
  after_create :send_admin_email

  # FIXME: Decouple presentation layer from persistence layer
  attribute :generate_mail, :boolean, default: true

  def users_not_to_notify
    @users_not_to_notify ||= Set.new
  end

  # all of the notifications will be sent to relevant users
  def users_to_notify
    Set.new.tap do |set|
      set.merge(User.in_use.ids) if all_users
      set.merge(User.administrators.ids) if admin_users
      set.merge(User.odr_users.ids) if odr_users
      set.merge(project_user_ids) if project
      set.merge(team.users.ids) if team
      set.add(user_id) if user_id

      set.subtract(users_not_to_notify)
    end
  end

  private

  def create_user_notifications
    users_to_notify.each do |user_id|
      user_notifications.create(user_id: user_id, generate_mail: generate_mail)
    end
  end

  def send_admin_email
    return unless generate_mail
    return unless admin_users
    NotificationMailer.send_admin_messages(self).deliver_later
  end

  # attempt to not tread on MBIS application behaviour for now until
  # notifications ana mail is fully decoupled
  def project_user_ids
    return [] if project_id.nil?

    project.users.internal.pluck(:id)
  end
end
