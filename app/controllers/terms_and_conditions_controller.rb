# This controller RESTfully manages the Terms and Conditions
class TermsAndConditionsController < ApplicationController
  skip_before_action :ensure_terms_accepted

  def index
  end

  def create
    session[:accepted_terms_and_conditions] = true
    current_user.update_attribute(:rejected_terms_count, 0)
    redirect_to root_url
  end

  def terms_rejected
    @user = current_user
    @user.update_attribute(:rejected_terms_count, @user.rejected_terms_count + 1)
    if @user.rejected_terms_count < 3
      sign_out @user
      redirect_to user_session_url, alert: "You have #{3 - @user.rejected_terms_count} \
        attempts to approve the terms and then your account will be locked"
    else
      current_user.lock_access!
      flash[:alert] = CONTENT_TEMPLATES['user_rejected_terms']['body'] %
                      { full_name: current_user.full_name }
      Notification.create!(title: 'User has declined the Terms and Conditions',
                           body: CONTENT_TEMPLATES['email_admin_rejected_terms']['body'] %
                               { full_name: current_user.full_name },
                           admin_users: true)
      v_username = current_user.full_name
      sign_out @user
      redirect_to user_session_url, alert: CONTENT_TEMPLATES['user_rejected_terms']['body'] %
                                           { full_name: v_username }
    end
  end
end
