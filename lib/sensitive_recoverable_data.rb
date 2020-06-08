# Module, to support storing secret data using a combination of public /
# private key and symmetric encryption.
#
# To encrypt, a public key is provided, and an optional temporary password.
# If a temporary password is set, the data can be decrypted using either that
# password, or using the private key.
# If not temporary password is set, a random one will be used, and the data can
# only be decrypted using the private key.
module SensitiveRecoverableData
  # Decrypt sensitive secret data, given temporary passwords, or a private key and its password
  # Returns the decrypted output data
  def self.decrypt_sensitive_data(password, temporary_password, rawdata, private_key_data)
    return if rawdata.blank?
    cipher = OpenSSL::Cipher.new('aes-256-cbc')
    cipher.decrypt
    if temporary_password.nil? || temporary_password.eql?('ADMIN')
      private_key = OpenSSL::PKey::RSA.new(private_key_data, password)
      # cipher.key = private_key.private_decrypt(rawdata[0..255])
      cipher.key = private_key.private_decrypt(rawdata[0..511])
    else
      cipher.key = Digest::SHA1.hexdigest(temporary_password)[0, cipher.key_len]
    end
    # cipher.iv = rawdata[256..271]
    # decrypted_data = cipher.update(rawdata[272..-1])
    cipher.iv = rawdata[512..527]
    decrypted_data = cipher.update(rawdata[528..-1])
    decrypted_data << cipher.final
  end

  # Encrypt sensitive secret data, given a public key file as a String
  # Returns the encrypted output data
  def self.encrypt_sensitive_data(secret_data, temporary_password, public_key_data)
    return if secret_data.blank?
    cipher = OpenSSL::Cipher.new('aes-256-cbc')
    cipher.encrypt
    cipher.key = random_key = if temporary_password.nil?
                                cipher.random_key
                              else
                                Digest::SHA1.hexdigest(temporary_password)[0, cipher.key_len]
                              end
    cipher.iv = random_iv = cipher.random_iv
    rawdata = cipher.update(secret_data)
    rawdata << cipher.final
    public_key = OpenSSL::PKey::RSA.new(public_key_data)
    public_key.public_encrypt(random_key) + random_iv + rawdata
  end
end
