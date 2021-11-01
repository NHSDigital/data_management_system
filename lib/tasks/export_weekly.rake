require 'fileutils'

namespace :export do
  namespace :weekly do
    desc <<~USAGE
      Export weekly MBIS Death data
      Syntax: rake export:weekly:death project_name='...' team_name='...' klass=... [filter=...] [week=YYYY-MM-DD] [extract_path=extracts/...]
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
      extract_path   = ENV.delete('extract_path').presence
      # Accepts month parameter, e.g. 2020-10, to run non-interactively
      if project_name.blank? || team_name.blank? || klass.blank?
        puts <<~USAGE
          Error: Missing required parameter.
          Syntax: rake export:weekly:death project_name='...' team_name='...' klass=... [filter=...] [week=YYYY-MM-DD] [extract_path=extracts/...]
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
      extract_path   ||= "extracts/#{fname_team}/#{fname_project}"

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
        lines = ['', "#{team_name.upcase} WEEKLY #{project_name.upcase} REPORT",
                 "DATE OF RUN: #{date.strftime('%Y%m%d')}",
                 ("FILTER: #{filter}" if filter),
                 "RECORDS SENT TO #{project_name.upcase} THIS MONTH: #{count}"]
        lines.each { |l| f << "#{l}\r\n" if l }
      end

      encryptor.compress_and_encrypt_zip(extract_passwd, extract_path, fname_zip, fname,
                                         fname_summary)

      puts "Created extract file #{fname_zip}"
      # TODO: Try to copy extract to smb destination
    end
  end

  desc <<~USAGE
    Export weekly MBIS Death data
    Syntax: rake export:weekly [weeks_ago=n] [import_weekly=n] [config=config/regular_extracts.csv] [e_type=PSBIRTH,PSDEATH]
    where extracts.csv is a CSV file with the following columns / example entries:

    e_type,klass,project_name,team_name,frequency,filter
    PSDEATH,Export::CancerDeathWeekly,name1,name2,weekly,cd
  USAGE
  task weekly: :'pseudo:keys:load' do
    e_types = ENV['e_types'].presence&.split(',') || %w[PSBIRTH PSDEATH]
    weeks_ago = ENV['weeks_ago'].presence&.to_i || 5
    import_weekly = !/\An/i.match?(ENV['import_weekly'])
    config_fname = ENV['config'] || 'config/regular_extracts.csv'
    unless File.exist?(config_fname)
      warn "ERROR: Configuration file #{config_fname} does not exist; aborting."
      exit 1
    end
    logger = ActiveSupport::Logger.new($stdout)
    logger.extend(ActiveSupport::Logger.broadcast(Rails.logger))
    if import_weekly
      old_quieter = ENV['quieter_import_weekly']
      ENV['quieter_import_weekly'] = 'y'
      Rake::Task['import:weekly'].invoke
      ENV['quieter_import_weekly'] = old_quieter
    end
    logger.warn "Running weekly / monthly exports for the past #{weeks_ago} weeks."

    # For each file
    start_date = weeks_ago.weeks.ago.to_date
    end_date = Time.zone.today
    begin
      # Export regular weekly / monthly extracts
      count = Export::Helpers::RakeHelper::RegularExtracts.
              new(config_fname, e_types, logger: logger).export_all(start_date, end_date)
      if count.zero?
        logger.warn "No new weekly / monthly extracts produced for e_types=#{e_types.join(',')}"
        logger.warn <<~USAGE.chomp
          For annual extracts, use:
            bin/rake export:birth or bin/rake export:death
          To run weekly extracts manually, use:
            bin/rake export:flu or bin/rake export:cdsc or bin/rake export:cd or
            bin/rake export:weekly:death or bin/rake export:weekly:birth
          To run monthly extracts manually (on the 4th week of each month), use:
            bin/rake export:aids or bin/rake export:ncd_monthly or
            bin/rake export:kitdeaths_monthly or bin/rake export:monthly:death or
            bin/rake export:monthly:birth
        USAGE
      else
        logger.warn "Exported #{count} extracts for e_types #{e_types.join(',')}"
      end
    rescue RuntimeError => e
      unless [e.message, e.cause&.message].any? do |message|
               'ERROR: export failures' == message
             end
        logger.warn 'To export batches individually, use bin/rake export:monthly:death etc.'
        raise
      end
      # Don't show backtrace for common, self-explanatory errors
      # Don't print "export failures" error because it'll already be logged
      # puts "#{e.class} #{e}"
      # puts "#{e.cause.class} #{e.cause}" if e.cause
      exit 1
    end
  end
end
