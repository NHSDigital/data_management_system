require 'fileutils'

namespace :export do
  namespace :weekly do
    desc <<~USAGE
      Export weekly MBIS Death data
      Syntax: rake export:weekly:death project_name='...' team_name='...' klass=... [filter=...] [week=YYYY-MM-DD]
    USAGE
    task death: :'pseudo:keys:load' do
      extractor      = Export::Helpers::RakeHelper::DeathExtractor
      encryptor      = Export::Helpers::RakeHelper::EncryptOutput
      data_root      = SafePath.new('mbis_data')
      project_name   = ENV.delete('project_name')
      team_name      = ENV.delete('team_name')
      klass          = ENV.delete('klass')&.constantize
      filter         = ENV.delete('filter')
      week           = ENV.delete('week')
      # Accepts month parameter, e.g. 2020-10, to run non-interactively
      if project_name.blank? || team_name.blank? || klass.blank?
        puts <<~USAGE
          Error: Missing required parameter.
          Syntax: rake export:weekly:death project_name='...' team_name='...' klass=... [filter=...] [month=YYYY-MM]
        USAGE
        exit 1
      end
      extract_passwd = encryptor.find_project_data_password(project_name, team_name)
      fname_patterns = if klass.respond_to?(:fname_patterns)
                         patterns = klass.fname_patterns(filter, :weekly)
                         patterns[0..1] + ['MTH%m_temp_%s.TXT', patterns[2]]
                       else
                         %w[MTH%Y-%mD_MBIS.TXT MTH%Y-%mP_MBIS.TXT MTH%Y-%m_temp_%s.TXT
                            MTH%Y-%m_MBIS.zip]
                       end
      fname_team     = team_name.parameterize(separator: '_')
      fname_project  = project_name.parameterize(separator: '_')
      extract_path   = "extracts/#{fname_team}/#{fname_project}"

      fname_patterns.map! do |fname_pattern|
        "#{extract_path}/%Y-%m-%d/#{fname_pattern}"
      end

      date, fnames, ebatch = extractor.pick_mbis_weekly_death_batch(project_name, fname_patterns,
                                                                    week: week)

      unless ebatch
        puts 'No batch selected - aborting.'
        exit
      end

      fname, fname_summary, _fname_tmp, fname_zip = fnames

      fname_full = data_root.join(fname)

      target_file = fname

      extractor.extract_mbis_weekly_death_file(ebatch, target_file, klass, filter)

      # Generate summary report file
      count = CSV.read(fname_full).size - 1

      File.open(data_root.join(fname_summary), 'w+') do |f|
        lines = [' ', "#{team_name.upcase} WEEKLY #{project_name.upcase} REPORT",
                 "DATE OF RUN: #{date.strftime('%Y%m%d')}",
                 "RECORDS SENT TO #{project_name.upcase} THIS MONTH    :     #{count}"]
        lines.each { |l| f << l + "\r\n" }
      end

      encryptor.compress_and_encrypt_zip(extract_passwd, extract_path, fname_zip, fname,
                                         fname_summary)

      puts "Created extract file #{fname_zip}"
      # TODO: Try to copy extract to smb destination
    end
  end
end
