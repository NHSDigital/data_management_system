# Logic for marking a User's Notification(s)
# This stores a copy of each message a user receives
# - we need to store a 'status' (ie read or not read) for each message for each user
class UserNotification < ApplicationRecord
  belongs_to :notification
  belongs_to :user
  after_create :send_email

  # FIXME: Decouple presentation layer from persistence layer
  attribute :generate_mail, :boolean, default: true

  # status can be new read deleted
  scope :unread, -> { where(status: 'new') }
  scope :read, -> { where(status: 'read') }
  scope :inbox, -> { where("status = 'read' or status = 'new'") }
  scope :deleted, -> { where(status: 'deleted') }

  scope :project, ->(project_id) {
    joins(:notification).
      where(notifications: { project_id: project_id })
  }

  # team also needs to include projects of team - so we need to get notifications that were sent to project members
  # not just
  scope :team, ->(team_id) {
    joins(:notification).
      where(<<~SQL, team_id: team_id)
        notifications.team_id = :team_id
        OR notifications.project_id IN (
          SELECT id
          FROM projects
          WHERE projects.team_id = :team_id
        )
      SQL
  }

  # once the notification is linked to specific user then send the email
  def send_email
    return unless generate_mail

    # Don't send multiple emails to admin users. mails are taking ~ 2.5 seconds to send
    # holding up the front end whenever a user is edited
    return if notification.admin_users
    begin
      NotificationMailer.send_message(notification, user).deliver_now
    rescue => exception
      metadata = { user_id: user.id }
      fingerprint, _log = NdrError.log(exception, metadata, nil)
      Rails.logger.info("Email failed to deliver: #{exception.message} [#{fingerprint.id}]")
    end
  end
end
