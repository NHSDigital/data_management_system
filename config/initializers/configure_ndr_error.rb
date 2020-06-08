Rails.application.config.to_prepare do
  NdrError.user_column = :user_id

  # FIXME: Log user ID:
  NdrError.log_parameters = ->(_request) { { user_id: nil } }

  NdrError.check_current_user_authentication = lambda do |context|
    current_user = context.current_user
    current_user ? current_user.can?(:read, :ndr_errors) : false
  end

  NdrError.check_current_user_permissions = lambda do |context|
    current_user = context.current_user
    current_user ? current_user.can?(:edit, :ndr_errors) : false
  end
end
