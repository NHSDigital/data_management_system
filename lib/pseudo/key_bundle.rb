module Pseudo
  # Contains logic for extracting shared secrets from
  # the current user's key bundle. Allows keys to be extracted
  # when supplied with a password (which is not retained). Password
  # defaults to the 'MBIS_KEK' environment variable.
  class KeyBundle
    def initialize(user = nil)
      @user = user || derive_user
    end

    def extract(key, passphrase = nil)
      passphrase ||= ENV['MBIS_KEK'] || ''
      yaml = decrypt(encrypted_bundle, passphrase)
      YAML.load(yaml)[key]
    end

    # Check that the bundle can be loaded OK
    def valid?(passphrase = nil)
      extract('dummy', passphrase)
      true
    rescue Errno::ENOENT, OpenSSL::Cipher::CipherError
      false
    end

    def keys(passphrase = nil)
      passphrase ||= ENV['MBIS_KEK'] || ''
      yaml = decrypt(encrypted_bundle, passphrase)
      YAML.load(yaml).keys.sort
    end

    private

    def derive_user
      Rails.env.test? ? 'unittest' : ENV['MBIS_KEK_USERNAME']
    end

    def bundle_path
      raise 'No bundle user specified in MBIS_KEK_USERNAME' if @user.blank?
      SafePath.new('key_bundles').join("#{@user}_mbis.kek")
    end

    def encrypted_bundle
      Base64.decode64 SafeFile.read(bundle_path)
    end

    def decrypt(ciphertext, passphrase)
      aes = OpenSSL::Cipher.new('AES-256-CBC')
      aes.decrypt
      aes.key = Digest::SHA256.digest(passphrase)

      aes.update(ciphertext) << aes.final
    end
  end
end
