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
  around_create :assign_to_users
  after_create :send_admin_email

  # FIXME: Decouple presentation layer from persistence layer
  attribute :generate_mail, :boolean, default: true

  # all of the notifications will be sent to relevant users
  def assign_to_users
    users = []
    users << User.in_use.ids if all_users
    users << User.administrators.ids if admin_users
    users << User.odr_users.ids if odr_users
    users << project_user_ids(project_id)
    users << Team.find(team_id).users.collect(&:id) if team_id
    users << user_id if user_id
    users.flatten.compact.uniq.each do |u|
      user_notifications.build(user_id: u, generate_mail: generate_mail)
    end

    yield
  end

  def send_admin_email
    return unless generate_mail
    return unless admin_users
    NotificationMailer.send_admin_messages(self).deliver_later
  end

  # attempt to not tread on MBIS application behaviour for now until
  # notifications ana mail is fully decoupled
  def project_user_ids(project_id)
    return if project_id.nil?

    project.users.internal.pluck(:id)
  end
end
