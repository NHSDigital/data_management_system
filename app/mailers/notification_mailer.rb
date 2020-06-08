class NotificationMailer < ApplicationMailer
  def send_message(notification, user)
    mail(to:           user.email,
         subject:      notification.title,
         sent_on:      Time.current,
         body:         notification.body)
  end

  def send_admin_messages(notification)
    # admins = User.administrators.map(&:email)
    mail(bcc:     User.administrators.map(&:email),
         subject: notification.title,
         sent_on: Time.current,
         body:    notification.body)
  end
end
