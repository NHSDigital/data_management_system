module Users
  # This controller allows users to change their password once logged in.
  class PasswordChangesController < ApplicationController
    def new
      render_new
    end

    def create
      if current_user.update_with_password(password_change_params)
        bypass_sign_in(current_user) # Update the session

        flash[:notice] = I18n.t('devise.registrations.updated')
        redirect_to root_url
      else
        render_new
      end
    end

    private

    def password_change_params
      fields = %i(password password_confirmation current_password)
      params.permit(user: fields)[:user]
    end

    def render_new
      render 'users/password_changes/new'
    end
  end
end
