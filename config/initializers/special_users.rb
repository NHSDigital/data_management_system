if Rails.env.test?
  ADMIN_USER_EMAILS = YAML.load_file("#{Rails.root}/test/admin_users.yml")
  ODR_USER_EMAILS = YAML.load_file("#{Rails.root}/test/odr_users.yml")
else
  # :nocov:
  ADMIN_USER_EMAILS = YAML.load_file("#{Rails.root}/config/admin_users.yml")
  ODR_USER_EMAILS = YAML.load_file("#{Rails.root}/config/odr_users.yml")
  # :nocov:
end

Rails.application.config.to_prepare do
  special_users = YAML.load_file(Rails.root.join('config', "special_users.#{Rails.env}.yml"))
  User.special_users = special_users.freeze
end
