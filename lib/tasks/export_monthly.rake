require 'fileutils'

namespace :export do
  desc 'Export AIDS monthly files interactively'
  task aids: [:environment, 'pseudo:keys:load'] do
    # Check keys are correctly configured
    pdp = Export::Helpers::RakeHelper::EncryptOutput.find_project_data_password(
      'Monthly ONS Deaths for HIV Surveillance', 'HIV and STI Department'
    )
    recipient = 'CDSC'
    fname_patterns = %w[HPAMTH%mD_MBIS.TXT HPAMTH%mP_MBIS.TXT HPAMTH%m_temp_%s.TXT
                        HPAMTH%Y-%m_MBIS.zip].
                     collect { |s| 'extracts/HIVAIDS Monthly Extract/%Y-%m-%d/' + s }
    date, (fn, fn_sum, fn_tmp,
           fn_zip), batches = Export::Helpers::RakeHelper::DeathExtractor.
                              pick_mbis_monthly_death_batches('AIDS', fname_patterns)
    unless batches
      puts 'No batch selected - aborting.'
      exit
    end
    fn_full = SafePath.new('mbis_data').join(fn)
    fn_tmp_full = SafePath.new('mbis_data').join(fn_tmp)
    batches.each_with_index do |eb, i|
      # Extract subsequent batches to a temporary file, then concatenate to the first file
      Export::Helpers::RakeHelper::DeathExtractor.
        extract_mbis_weekly_death_file(eb, i.zero? ? fn : fn_tmp, 'Export::AidsDeathsMonthly')
      unless i.zero?
        File.open(fn_full, 'a') { |f| f << File.read(fn_tmp_full) }
        FileUtils.rm(fn_tmp_full)
      end
    end
    # Generate summary report file
    counts = { 'AIDS99' => File.readlines(fn_full).size }
    group_names = { 'AIDS99' => 'AIDS' }
    File.open(SafePath.new('mbis_data').join(fn_sum), 'w+') do |f|
      group_names.each do |group, name|
        lines = [' ', "#{recipient} MONTHLY #{name} REPORT",
                 "DATE OF RUN: #{date.strftime('%Y%m%d')}",
                 "RECORDS SENT TO #{recipient} THIS MONTH    :     #{counts[group] || 0}"]
        lines.each { |l| f << l + "\r\n" }
      end
    end
    Export::Helpers::RakeHelper::EncryptOutput.
      compress_and_encrypt_zip(pdp, 'extracts/HIVAIDS Monthly Extract',
                               fn_zip, fn, fn_sum)
    puts "Created extract file #{fn_zip}"
  end

  namespace :monthly do
    desc <<~USAGE
      Export monthly MBIS Death data
      Syntax: rake export:monthly:death project_name='...' team_name='...' klass=... [filter=...] [month=YYYY-MM]
    USAGE
    task death: :'pseudo:keys:load' do
      extractor      = Export::Helpers::RakeHelper::DeathExtractor
      encryptor      = Export::Helpers::RakeHelper::EncryptOutput
      data_root      = SafePath.new('mbis_data')
      project_name   = ENV.delete('project_name')
      team_name      = ENV.delete('team_name')
      klass          = ENV.delete('klass')&.constantize
      filter         = ENV.delete('filter')
      # Accepts month parameter, e.g. 2020-10, to run non-interactively
      if project_name.blank? || team_name.blank? || klass.blank?
        puts <<~USAGE
          Error: Missing required parameter.
          Syntax: rake export:monthly:death project_name='...' team_name='...' klass=... [filter=...] [month=YYYY-MM]
        USAGE
        exit 1
      end
      extract_passwd = encryptor.find_project_data_password(project_name, team_name)
      fname_patterns = if klass.respond_to?(:fname_patterns)
                         patterns = klass.fname_patterns(filter, :monthly)
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

      date, fnames, batches = extractor.pick_mbis_monthly_death_batches(project_name, fname_patterns)

      unless batches
        puts 'No batch selected - aborting.'
        exit
      end

      fname, fname_summary, fname_tmp, fname_zip = fnames

      fname_full     = data_root.join(fname)
      fname_tmp_full = data_root.join(fname_tmp)

      batches.each_with_index do |ebatch, index|
        # Extract subsequent batches to a temporary file, then concatenate to the first file
        target_file = index.zero? ? fname : fname_tmp

        extractor.extract_mbis_weekly_death_file(ebatch, target_file, klass, filter)

        # FIXME: Assumes extracted file has 1 header line and 0 footer lines (as per `SimpleCsv`),
        # but extract classes are free to define header/footer enumerables of any length...
        unless index.zero?
          File.open(fname_full, 'a') do |f|
            File.foreach(fname_tmp_full).with_index do |line, line_number|
              f << line if line_number.positive?
            end
          end
          FileUtils.rm(fname_tmp_full)
        end
      end

      # Generate summary report file
      count = CSV.read(fname_full).size - 1

      File.open(data_root.join(fname_summary), 'w+') do |f|
        lines = [' ', "#{team_name.upcase} MONTHLY #{project_name.upcase} REPORT",
                 "DATE OF RUN: #{date.strftime('%Y%m%d')}",
                 "RECORDS SENT TO #{project_name.upcase} THIS MONTH    :     #{count}"]
        lines.each { |l| f << l + "\r\n" }
      end

      encryptor.compress_and_encrypt_zip(extract_passwd, extract_path, fname_zip, fname, fname_summary)

      puts "Created extract file #{fname_zip}"
      # TODO: Try to copy extract to smb destination
    end
  end
end
