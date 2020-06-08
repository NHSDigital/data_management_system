require 'fileutils'

namespace :export do
  desc 'Export CDSC weekly files interactively'
  task ncd_covid19: [:environment, 'pseudo:keys:load'] do
    # Check keys are correctly configured
    pdp = Export::Helpers::RakeHelper::EncryptOutput.find_project_data_password(
      'Non-Communicable Disease: Mortality Surveillance', 'Data Lake'
    )
    recipient = 'NCDEXTRA'
    fname_patterns = %w[NCDEXTRA%Y-%m_MBIS.csv NCDEXTRA%Y-%m_summary_MBIS.TXT NCDEXTRA%Y-%m_temp_%s.csv
                        NCDEXTRA%Y-%m_MBIS.zip].
                     collect { |s| 'extracts/NCD Covid19 Extra/%Y-%m-%d/' + s }
    date, (fn, fn_sum, fn_tmp,
           fn_zip), batches = Export::Helpers::RakeHelper::DeathExtractor.
                              pick_mbis_monthly_death_batches('NCDEXTRA', fname_patterns)
    unless batches
      puts 'No batch selected - aborting.'
      exit
    end
    fn_full = SafePath.new('mbis_data').join(fn)
    fn_tmp_full = SafePath.new('mbis_data').join(fn_tmp)
    batches.each_with_index do |eb, i|
      # Extract subsequent batches to a temporary file, then concatenate to the first file
      Export::Helpers::RakeHelper::DeathExtractor.
        extract_mbis_weekly_death_file(eb, i.zero? ? fn : fn_tmp,
                                       'Export::NonCommunicableDiseaseCovid19Extras')
      unless i.zero?
        # Skip header row when appending
        File.open(fn_full, 'a') { |f| f << File.read(fn_tmp_full).split("\r\n", 2)[1] }
        FileUtils.rm(fn_tmp_full)
      end
    end
    # Generate summary report file
    counts = { 'NCDEXTRA' => File.readlines(fn_full).size - 1 }
    group_names = { 'NCDEXTRA' => 'NON COMMUNICABLE DISEASE COVID19 EXTRA' }
    File.open(SafePath.new('mbis_data').join(fn_sum), 'w+') do |f|
      group_names.each do |group, name|
        lines = [' ', "#{recipient} MONTHLY #{name} REPORT",
                 "DATE OF RUN: #{date.strftime('%Y%m%d')}",
                 "RECORDS SENT TO #{recipient} THIS MONTH    :     #{counts[group] || 0}"]
        lines.each { |l| f << l + "\r\n" }
      end
    end
    Export::Helpers::RakeHelper::EncryptOutput.
      compress_and_encrypt_zip(pdp, 'extracts/NCD Covid19 Extra',
                               fn_zip, fn, fn_sum)
    puts "Created extract file #{fn_zip}"
  end
end
