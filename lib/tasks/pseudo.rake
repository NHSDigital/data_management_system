require 'highline/import'
require 'base64'
require 'fileutils'

namespace :pseudo do
  # Manage pseudonymisation keys
  namespace :keys do
    desc <<~EOT
    Load and check key bundle, prompting for username and password if a tty.
    Alternatively, preconfigure environment, e.g. in a shell:
      read -rep "Enter MBIS_KEK_USERNAME: " MBIS_KEK_USERNAME; export MBIS_KEK_USERNAME
      read -rsp "Enter MBIS_KEK password: " MBIS_KEK; echo; export MBIS_KEK
    EOT
    task load: :environment do
      bundle = nil
      max_tries = $stdin.tty? ? 3 : 1
      max_tries.times do |i|
        if $stdin.tty?
          ENV['MBIS_KEK_USERNAME'] ||= ask('Enter MBIS_KEK_USERNAME: ') do |q|
            q.validate = /./
            q.responses[:not_valid] = 'Must not be blank.'
          end
          ENV['MBIS_KEK'] ||= ask("Enter MBIS_KEK for #{ENV['MBIS_KEK_USERNAME'].inspect}: ") do |q|
            q.echo = '*'
            q.validate = /./
            q.responses[:not_valid] = 'Must not be blank.'
          end
        end
        bundle = Pseudo::KeyBundle.new
        break if bundle.valid?
        puts 'Error: Invalid key bundle username MBIS_KEK_USERNAME or passphrase MBIS_KEK'
        ENV['MBIS_KEK_USERNAME'] = ENV['MBIS_KEK'] = nil
        exit(1) if i == max_tries - 1
      end
      Pseudo::Ppatient.keystore = Pseudo::KeyStoreLocal.new(bundle)
    end

    desc 'Manage pseudonymisation keys'
    task manage: :load do
      bundle = Pseudo::KeyBundle.new
      update_bundle = lambda do |callback, bundle_path = nil|
        # Use private methods to force in-memory bundle decrypt and re-encryption
        bundle_path ||= bundle.send(:bundle_path)
        yaml = bundle.send(:decrypt, bundle.send(:encrypted_bundle), ENV['MBIS_KEK'])
        bundle_data = YAML.load(yaml)
        callback.call(bundle_data)
        bak = SafePath.new('key_bundles').join("#{ENV['MBIS_KEK_USERNAME']}_mbis_" \
                                               "#{Time.now.strftime('%Y%m%d_%Hh%M%S')}.kek")
        FileUtils.cp(bundle_path, bak, verbose: true, preserve: true) if File.exist?(bundle_path)
        aes = OpenSSL::Cipher.new('AES-256-CBC')
        aes.encrypt
        aes.key = Digest::SHA256.digest(ENV['MBIS_KEK'])
        encrypted_bundle = Base64.strict_encode64(aes.update(bundle_data.to_yaml) + aes.final)
        File.open(bundle_path, 'w') { |f| f << encrypted_bundle }
        puts "Saved updated bundle #{bundle_path}."
      end
      read_key_name = lambda do |msg|
        ask("#{msg}: ") { |q| q.validate = /\A:?[a-z0-9_]+\Z/ }.delete(':').to_sym
      end
      loop do
        HighLine.choose do |menu|
          menu.choice('Check key bundle and database keys for consistency') do
            bundle_keys = bundle.keys
            puts "Bundle keys: #{bundle_keys.inspect}"
            pseudo_keys = bundle_keys.select do |k|
              entry = bundle.extract(k)
              entry.is_a?(Hash) && entry[:salt1]
            end
            puts "Pseudonymisation keys: #{pseudo_keys.inspect}"
            db_keys = Pseudo::PseudonymisationKey.pluck('key_name').collect(&:to_sym).sort
            puts "Database keys: #{db_keys.inspect}"
            bundle_only_keys = pseudo_keys - db_keys
            if bundle_only_keys.empty?
              puts "All bundle keys are in the #{Rails.env} database.\n\n"
              next
            end
            puts "Warning: Keys only in the bundle: #{bundle_only_keys.inspect}"
            bundle_only_keys.each do |key|
              next unless HighLine.agree("Add key #{key.inspect} to the database [y/n]?")
              pk = Pseudo::PseudonymisationKey.where(key_name: key.to_s).first_or_create
              raise "Could not create key #{key}: #{pk.errors.to_h.inspect}" unless pk.persisted?
              puts "Database key #{key} created in #{Rails.env} environment"
            end
          end
          menu.choice('Copy key bundle for another user') do
            new_username = ask('Enter new username: ') do |q|
              q.validate = /./
              q.responses[:not_valid] = 'Must not be blank.'
            end
            new_kek = ask("Enter MBIS_KEK for #{new_username.inspect}: ") do |q|
              q.echo = '*'
              q.validate = /.{16,}/
              # 12 bytes, base64 encoded, gives 16 characters, which could be cracked
              # (at 10^9 attempts per second) in an average of 10^12 years.
              q.responses[:not_valid] = 'Must be 16+ characters, e.g. openssl rand 32 -base64'
            end
            new_bundle_path = Pseudo::KeyBundle.new(new_username).send(:bundle_path)
            update_bundle.call(-> (_bundle_data) { ENV['MBIS_KEK'] = new_kek }, new_bundle_path)
          end
          menu.choice('Add a key to your bundle') do
            puts "Existing keys: #{bundle.keys.inspect}"
            key_name = read_key_name.call('Enter new key name')
            allowed_modes = %w[pseudonymise_nhsnumber_only
                               pseudonymise_nhsnumber_postcode_birthdate encrypt string]
            puts <<~EOT
              mode is #{allowed_modes.join(' or ')}
              mode 'string' is for simple textual key/values. Other modes are for pseudonymisation:
              salt1 is for pseudonymisation
              salt2 is for encrypting demographics
              salt3 (optional) is for encrypting clinical data
              salt4 (optional) is for encrypting rawtext / mixed demographics and clinical data
              Each key should be 64 lower case hex characters, or 'auto' to auto-generate
            EOT
            mode = ask('mode: ') { |q| q.in = allowed_modes }
            if mode == 'string'
              print 'Enter multi-line key value, ^D to terminate: '
              lines = STDIN.readlines
              bundle_entry = lines.join
              bundle_entry.chomp! if lines.size == 1 # No newline at the end of single line entries
            else
              gen_salt = lambda do |name, required|
                re = required ? /\A(auto|[a-z0-9]{64})\Z/ : /\A(|auto|[a-z0-9]{64})\Z/
                salt = ask("#{name}: ") { |q| q.validate = re }
                return salt.blank? ? nil : salt unless salt == 'auto'
                SecureRandom.random_bytes(32).unpack('h*')[0].tap { |s| puts "#{name}: #{s}" }
              end
              bundle_entry = {
                salt1: gen_salt.call('salt1', true),
                salt2: gen_salt.call('salt2', true),
                salt3: gen_salt.call('salt3', false),
                salt4: gen_salt.call('salt4', false),
                mode: mode
              }.select { |_k, v| v.present? }
            end
            update_bundle.call(-> (bundle_data) { bundle_data[key_name] = bundle_entry })
            puts
          end
          menu.choice('Delete a key from your bundle') do
            puts "Existing keys: #{bundle.keys.inspect}"
            key_name = read_key_name.call('Enter key name to delete')
            unless bundle.keys.include?(key_name)
              puts "Unknown key #{key_name.inspect}"
              next
            end
            update_bundle.call(-> (bundle_data) { bundle_data.delete(key_name) })
            raise('Error: key deletion failed') if bundle.keys.include?(key_name)
            puts 'Key deleted successfully.\n\n'
          end
          menu.choice('Export key bundle for TeamPass backup [TODO]') do
            raise 'Comment out this line if you need to dump keys'
            bundle_keys = bundle.keys
            puts "# Bundle keys: #{bundle_keys.inspect} at #{Time.now}"
            bundle_keys.each do |k|
              entry = bundle.extract(k)
              puts({ k => entry }.to_yaml)
            end
          end
          menu.choice('Rebuild config/keys/unittest_mbis.kek [TODO]') do
            raise 'Not yet implemented'
          end if ENV['MBIS_KEK_USERNAME'] == 'unittest'
          menu.choice('Exit') do
            exit
          end
        end
      end
    end
  end
end
