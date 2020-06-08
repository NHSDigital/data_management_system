require 'sensitive_recoverable_data'

# Stores a password for automatically encrypting data releases from MBIS.
# This uses public / private key encryption, so the password in this record can
# only be recovered using the private key.
# The private key passphrase should be in users' key bundles
# The public key can be added to config/keys in each deployment
#
# For details on key generation, see 'Data encryption' section in biobank_request/README.rdoc
#
# To create a new password:
#   pdp=ProjectDataPassword.new(project_id: 54)
#   pdp.secret_data = SecureRandom.hex
#   pdp.save!
class ProjectDataPassword < ApplicationRecord
  belongs_to :project
  attr_accessor :secret_data
  attr_accessor :temporary_password
  before_save :encrypt_sensitive

  # Don't use paper_trail, as passwords may need to be securely destroyed.

  def decrypt_sensitive(password, temporary_password)
    return unless rawdata?
    SensitiveRecoverableData.decrypt_sensitive_data(password, temporary_password,
                                                    rawdata, private_key_data)
  end

  private

  def encrypt_sensitive
    return if secret_data.blank?
    public_key_data = File.read(public_key_file)
    self.rawdata = SensitiveRecoverableData.encrypt_sensitive_data(secret_data, temporary_password,
                                                                   public_key_data)
  end

  def private_key_data
    key = :mbis_project_data_passwords_pem
    pem = Pseudo::KeyBundle.new.extract(key)
    # Passphrase is Pseudo::KeyBundle.new.extract(:mbis_project_data_passwords_passphrase)
    return pem if pem
    raise ArgumentError, "Key bundle is missing key #{key.inspect}"
  end

  def public_key_file
    # ? Consider making this configurable, e.g. in ApplicationSettings.site.public_key_file
    SafePath.new('key_bundles').join('mbis_project_data_passwords_20180323_public.pem')
  end
end
