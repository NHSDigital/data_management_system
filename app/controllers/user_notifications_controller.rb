# This controller restfully manages MBIS notifications
class UserNotificationsController < ApplicationController
  # load_and_authorize_resource
  respond_to :js

  def index
    @notifications = Notification.all.order('created_at desc').limit(250)
  end


  def mark_as_read
    @un = UserNotification.find(params[:id])
    @un.update(user_notification_params)
    respond_to do |format|
      format.js do
      end
    end
  end

  # DELETE /notifications/1
  def destroy
    @notification = UserNotification.find(params[:id])
    if @notification.update(status: 'deleted')
      error_message = 'Notification deleted'
      respond_to do |format|
        format.html { redirect_to notifications_path, alert: error_message }
      end
    end
  end

  private

  def user_notification_params
    params.require(:user_notification).permit(:status)
  end
end
