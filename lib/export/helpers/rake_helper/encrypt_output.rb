module Export
  module Helpers
    # Helper methods, for inclusion into rake tasks
    module RakeHelper
      # Helpers to encrypt MBIS output
      module EncryptOutput
        # Find the active password entry for a project
        def self.find_project_data_password(name, team_name)
          pdp_scope = if team_name
                        ProjectDataPassword.joins(project: :team).
                          where(projects: { name: name }, teams: { name: team_name })
                      else
                        ProjectDataPassword.joins(:project).
                          where(projects: { name: name, team_id: nil })
                      end
          pdp_scope = pdp_scope.where('expired is null or expired > ?', Time.zone.today)
          pdp_count = pdp_scope.count
          unless pdp_count == 1
            raise ArgumentError, "#{pdp_count} passwords found for project with name: " \
                                 "#{name.inspect}, team_name: #{team_name.inspect}"
          end
          pdp_scope.first
        end

        # Compress and encrypt output files
        # Remove common base_dir prefixes to ensure simple filename paths in the zip file
        def self.compress_and_encrypt_zip(pdp, base_dir, fn_zip, *fnames)
          base_dir += '/' if base_dir.present? && !base_dir.end_with?('?')
          old_wd = Dir.pwd
          begin
            Dir.chdir(SafePath.new('mbis_data').join(base_dir))
            strip_prefix = ->(s, pref) { s.start_with?(pref) ? s[pref.size..-1] : s }
            fn_zip = strip_prefix.call(fn_zip, base_dir)
            fnames = fnames.collect { |s| strip_prefix.call(s, base_dir) }
            passphrase = Pseudo::KeyBundle.new.extract(:mbis_project_data_passwords_passphrase)
            zip_password = pdp.decrypt_sensitive(passphrase, nil)
            puts "Compressing with zip password #{zip_password.inspect}"
            system_args0 = %w[7za a -mx=9 -mm=Deflate -mem=AES256 -tzip -sdel]
            system_args1 = [fn_zip] + fnames
            puts "Running: #{system_args0.join(' ')} -p[SECRET] #{system_args1.join(' ')}"
            # E.g.: 7za a -mx=9 -mm=Deflate -mem=AES256 -tzip -p#
            #       2018-01-13/PAN180113_MBIS.zip 2018-01-13/PAN180113_MBIS.TXT -sdel
            system(*system_args0, "-p#{zip_password}", *system_args1)
          rescue
            Dir.chdir(old_wd)
            raise
          end
        end
      end
    end
  end
end
