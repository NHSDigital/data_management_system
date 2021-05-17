# RESTfully manages `Communication` resources
class CommunicationsController < ApplicationController
  load_and_authorize_resource :project
  load_and_authorize_resource through: :project, shallow: true

  # Ensure that any associations are correctly scoped to the project.
  with_options only: %i[create] do
    before_action :set_parent
    before_action :set_sender
    before_action :set_recipient
  end

  def index
    @communications = @communications.
                      includes(:parent, :sender, :recipient).
                      order(contacted_at: :desc, id: :desc)

    locals = {
      project: @project,
      communications: @communications,
      comments_count: @communications.joins(:comments).group(:id).count
    }

    respond_to do |format|
      format.html { render partial: 'communications', locals: locals, content_type: :html }
    end
  end

  def new
    respond_to do |format|
      format.js
    end
  end

  def create
    @communication.save

    respond_to do |format|
      format.js
    end
  end

  def destroy
    @communication.destroy

    respond_to do |format|
      format.js
    end
  end

  private

  def resource_params
    params.require(:communication).
      permit(:parent_id, :sender_id, :recipient_id, :contacted_at, :medium)
  end

  def set_parent
    return unless id ||= params.dig(:communication, :parent_id)

    @communication.parent = @project.communications.find_by(id: id)
  end

  def set_sender
    return unless id ||= params.dig(:communication, :sender_id)

    @communication.sender = @project.users.find_by(id: id)
  end

  def set_recipient
    return unless id ||= params.dig(:communication, :recipient_id)

    @communication.recipient = @project.users.find_by(id: id)
  end
end
