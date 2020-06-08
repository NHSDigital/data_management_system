if Rails.env.test?
  VALID_YUBIKEYS = YAML.load_file("#{Rails.root.to_s}/test/user_yubikeys.yml")
else
  VALID_YUBIKEYS = YAML.load_file("#{Rails.root.to_s}/config/user_yubikeys.yml")
end
