module Users
  # Override standard devise forgot password actions
  class PasswordsController < Devise::PasswordsController
    def new
      super
    end

    def create
      user = User.where(email: resource_params[:email]).first
      if user.update(z_user_status_id: ZUserStatus.where(name: 'Lockout').first.id)
        flash[:alert] = CONTENT_TEMPLATES['user_forgot_password']['body'] %
                        { full_name: user.full_name }
        user.forgot_password_notification
        respond_with({}, location: '/users/sign_in')
      else
        respond_with(resource)
      end
    rescue
      flash[:alert] = 'Could not find user account.'
      respond_with({}, location: '/users/password/new')
    end

    # PUT /resource/password
    def update
      self.resource = resource_class.reset_password_by_token(resource_params)
      yield resource if block_given?

      if resource.errors.empty?
        resource.unlock_access! if unlockable?(resource)
        resource.update(z_user_status_id: ZUserStatus.where(name: 'Active').first.id)
        if Devise.sign_in_after_reset_password
          flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
          set_flash_message!(:notice, flash_message)
          sign_in(resource_name, resource)
        else
          set_flash_message!(:notice, :updated_not_active)
        end
        respond_with resource, location: after_resetting_password_path_for(resource)
      else
        set_minimum_password_length
        respond_with resource
      end
    end
  end
end
