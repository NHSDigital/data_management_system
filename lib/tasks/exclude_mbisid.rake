namespace :export do
  desc <<~USAGE
    Add an MBISID to the opt-out list
    Runs interactively or via environment variable mbisid.
    Syntax: rake export:exclude_mbisid [new_mbisid_file=true] [mbisid=...]
  USAGE
  task exclude_mbisid: :environment do
    fname = ExcludedMbisid::EXCLUSION_FILENAME
    puts "Ensuring that #{fname} is up-to-date."
    credentials_repo = 'https://ndr-svn.phe.gov.uk/svn/encrypted-credentials-store/mbis_front/base'
    new_mbisid_file = ENV['new_mbisid_file'] == 'true'
    unless system('svn', 'export', '--force', "#{credentials_repo}/#{fname}", fname) ||
           new_mbisid_file
      warn <<~MSG
        Cannot connect to credentials repository: aborting

        If this is a brand new exclusion file, and no file exists in
        #{credentials_repo}/#{fname}
        then to create a new credentials file, run
        rake export:exclude_mbisid new_mbisid_file=true mbisid='#{ExcludedMbisid::DUMMY_MBISID}'
      MSG
      exit 1
    end

    exclusion_file = Rails.root.join(fname)
    unless new_mbisid_file ||
           (exclusion_file.exist? && ExcludedMbisid.excluded_mbisid?(ExcludedMbisid::DUMMY_MBISID))
      warn 'Error: MBISID exclusion list cannot be loaded: aborting'
      exit 1
    end

    print 'Enter MBISID to add to opt-out list [or blank to just redeploy]: '
    if ENV['mbisid'].present?
      mbisid = ENV['mbisid']
      puts mbisid
    else
      mbisid = $stdin.readline.chomp
    end
    unless mbisid.blank? || ExcludedMbisid::MBISID_FORMAT.match?(mbisid)
      puts "Invalid MBISID #{mbisid.inspect}, aborting."
      exit(1)
    end
    if ExcludedMbisid.excluded_mbisid?(mbisid)
      puts 'Already excluded, aborting.'
      exit(1)
    end
    if mbisid.present?
      today_iso = Time.current.strftime('%Y-%m-%d')
      comment = if new_mbisid_file && mbisid == ExcludedMbisid::DUMMY_MBISID
                  'Dummy MBISID for testing'
                else
                  "Exclusion requested #{today_iso}"
                end
      ExcludedMbisid.exclude_mbisid!(mbisid, comment)
      # system <<~CMD
      #   RAILS_MASTER_KEY="#{Rails.application.credentials.excluded_mbisid_key}" \
      #     bin/rails encrypted:edit config/excluded_mbisids.yml.enc
      # CMD
      check = `bundle exec rails runner "p(ExcludedMbisid.excluded_mbisid?('#{mbisid}'))"`.chomp
      raise('ERROR: MBISID not excluded after file changed. Aborting.') unless check == 'true'

      puts 'MBISID exclusion added: committing change to repository.'
      Dir.mktmpdir('excluded_mbisids') do |tmpdir|
        system('svn', 'checkout', credentials_repo, tmpdir, '--depth', 'empty')
        system('svn', 'up', '--parents', "#{tmpdir}/#{fname}")
        FileUtils.cp(exclusion_file, "#{tmpdir}/#{fname}")
        system('svn', 'add', "#{tmpdir}/#{fname}") if new_mbisid_file
        commit_msg = '# mbis_front / data_management_system: Updated encrypted list of excluded ' \
                     "MBISIDs from #{today_iso}."
        system('svn', 'commit', '-m', commit_msg, tmpdir)
      end

      puts 'MBISID exclusion added: deploying change.'
    else
      puts 'No MBISID specified; redeploying current MBISID exclusion list:'
    end
    %w[mbis_god_live].each do |dest|
      system "bundle exec cap #{dest} deploy:upload FILES=" \
             'config/excluded_mbisids.yml.enc deploy:restart'
    end
  end
end
