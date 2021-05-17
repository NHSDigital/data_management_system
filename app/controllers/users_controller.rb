# This controller RESTfully manages MBIS users
# TODO: Use as much of idiomatic CanCan as possible.
class UsersController < ApplicationController
  load_and_authorize_resource

  respond_to :js, :html

  def index
    # @users
    @users = @users.search(params: search_params, greedy: false).
             paginate(page: params[:page], per_page: 15).
             order(updated_at: :desc)
  end

  def new
    @admin_readonly = !current_user.administrator? && !current_user.application_manager? &&
                      !current_user.senior_application_manager?
  end

  def show
    @readonly = true
  end

  def edit
    @admin_readonly = !current_user.administrator? && !current_user.application_manager? &&
                      !current_user.senior_application_manager?
  end

  # TODO: Use NdrSupport for password generation.
  # TODO: Can we avoid hardcoded passwords in development/test?
  def create
    @user = User.new(user_params)
    generated_password = if Rails.env.production?
                           Devise.friendly_token.first(12).scan(/(.{3})/).join(' ')
                         else
                           'Password1*'
                         end
    @user.password_confirmation = @user.password = generated_password

    if @user.save
      @user.send_reset_password_instructions
      redirect_to users_url, notice: 'User was successfully created and has ' \
                                     'been sent instructions on how to set password'
    else
      render :new
    end
  end

  def update
    check_for_user_status_updates # move to model before_save ?
    if @user.update(user_params)
      respond_to do |format|
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.js
      end
    else
      render :edit
    end
  end

  def check_for_user_status_updates
    return if @user.z_user_status_id == user_params[:z_user_status_id]
    lockout_status_id = ZUserStatus.where(name: 'Lockout').first.id
    if user_params[:z_user_status_id] != lockout_status_id && !@user.locked_at.nil?
      @user.unlock_access!
    end
    if user_params[:z_user_status_id] == lockout_status_id && @user.locked_at.nil?
      @user.lock_access!
    end
    if user_params[:z_user_status_id] == ZUserStatus.where(name: 'Reset').first.id.to_s
      @user.send_reset_password_instructions
    end
  end

  def destroy
    return if cannot?(:destroy, @user)
    if @user == current_user
      redirect_to @user, alert: "You can't delete the current user"
    elsif @user.project_senior_user?
      redirect_to @user, alert: "You can't delete a Project senior user"
    else
      @user.update!(z_user_status_id: ZUserStatus.where(name: 'Deleted').first.id)
      redirect_to users_url, notice: "User #{@user.full_name} was successfully deleted."
    end
  end

  def filter_delegates_by_division
    @filtered_delegates  = User.in_use.delegate_users.order('last_name')
    selected_division_id = params[:selected_division_id]

    @filtered_delegates.where!(division_id: selected_division_id) if selected_division_id.present?
  end

  def teams
    @user = User.find(params[:user_id])
  end

  def projects
    @user = User.find(params[:user_id])
  end

  private

  # Only allow a trusted parameter "white list" through.
  def user_params
    params.require(:user).permit(:first_name, :last_name, :username, :email, :postcode, :telephone,
                                 :mobile, :grade, :location, :z_user_status_id, :notes, :job_title,
                                 :directorate_id, :division_id, :delegate_user,
                                 :employment, :line_manager_name, :line_manager_email,
                                 :line_manager_telephone, :contract_start_date,
                                 :contract_end_date, team_ids: [])
  end

  def search_params
    search_term = params.dig(:search, :name)

    params.fetch(:search, {}).
      merge(
        first_name: search_term,
        last_name:  search_term,
        email:      search_term,
        username:   search_term
      ).
      permit(:first_name, :last_name, :email, :username)
  end
end
