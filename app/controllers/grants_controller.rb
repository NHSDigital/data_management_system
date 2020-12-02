# Controller for managing role grants across MBIS.
class GrantsController < ApplicationController
  load_and_authorize_resource :user

  # Authorise the parent resource, @user, for :edit_grants instead of the default :read
  before_action :authorize_user_for_editing, except: [:index]

  # Load grants through user, we'll authorize each grant individually:
  load_resource :grant, through: :user

  def index
    @grants = @user.grants
  end

  def edit_team; end

  def edit_system; end

  def edit_project; end
  
  def update
    if perform_authorized_grant_updates!(grant_matrix)
      flash[:notice] = 'User grants updated.'
      redirect_to user_grants_url(@user)
    else
      flash.now[:alert] = 'Cannot remove all grants!'
      render :index
    end
  end

  def create; end

  private

  def grant_matrix
    GrantMatrix.new(params).call
  end

  def authorize_user_for_editing
    @user ||= current_user
    authorize!(:edit_grants, @user)
  end

  def perform_authorized_grant_updates!(clean_hash)
    current_grants = @user.grants.pluck(:id).sort
    updated_grants = nil
    @user.transaction do
      clean_hash.each do |roleable_type, granted|
        grant = @user.grants.find_or_initialize_by(roleable_type)
        authorize!(:toggle, grant)

        if granted
          grant.save! unless grant.persisted?
        else
          grant.destroy! if grant.persisted?
        end
      end

      @user.reload
      updated_grants = @user.grants.pluck(:id).sort
      raise ActiveRecord::Rollback if current_grants == updated_grants
    end

    current_grants != updated_grants
  end
end
