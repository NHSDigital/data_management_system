# This controller restfully manages MBIS notifications
class NotificationsController < ApplicationController
  # load_and_authorize_resource
  respond_to :js, :html

  def new
    @notification = Notification.new
  end

  def create
    @notification = Notification.new(notification_params)
    if @notification.save
      flash[:notice] = 'All users sucessfully messaged'
      flash.keep(:notice)
      render js: "window.location = '/'"
    else
      render :new
    end
  end

  def index
    if !params[:deleted].nil? && params[:deleted] == '1'
      @notifications = current_user.user_notifications.deleted.order('created_at desc')
    else
      @notifications = current_user.user_notifications.inbox.order('created_at desc')
    end
    # these are for search boxes
    @teams = [['All', 'All']]
    if current_user.administrator? || current_user.odr?
      @teams.concat Team.active.order('name').collect { |a| [a.name, a.id] }
    else
      @teams.concat current_user.teams.active.order('name').collect { |a| [a.name, a.id] }
    end

    if !params[:team].nil? && params[:team] != 'All'
      @notifications = @notifications.team(params[:team])
      # projects = Team.find(params[:team]).projects.collect(&:id)
    end
    respond_to do |format|
      format.js {}
      format.html {}
    end
  end

  private

  # Only allow a trusted parameter "white list" through.
  def notification_params
    params.require(:notification).permit(:title, :body, :created_by, :all_users)
  end
end
