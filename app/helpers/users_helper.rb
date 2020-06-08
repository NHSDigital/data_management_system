module UsersHelper
  # A User that can do most of the things an admin can do (Application Manager)
  def super_user?(user)
    roles = %i[administrator? application_manager? senior_application_manager? odr?]
    roles.any? { |role|  user.send(role) }
  end

  def mode_text(user)
    return unless user
    return 'ADMIN' if user.administrator?
    return 'APPLICATION MANAGER' if user.application_manager?
    return 'SENIOR APPLICATION MANAGER' if user.senior_application_manager?
    return 'ODR' if user.odr?
  end
end