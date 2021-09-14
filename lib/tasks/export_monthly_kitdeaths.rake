require 'fileutils'

namespace :export do
  desc 'Export KIT deaths weekly files interactively'
  task kitdeaths_monthly: [:environment, 'pseudo:keys:load'] do
    # Check keys are correctly configured
    pdp = Export::Helpers::RakeHelper::EncryptOutput.find_project_data_password(
      'DataLake_DeathsAnnualGS_2016', 'Data Lake'
    )
    recipient = 'DATA LAKE'
    fname_patterns = %w[KITDEATHS%Y-%m_MBIS.csv KITDEATHS%Y-%m_summary_MBIS.TXT KITDEATHS%Y-%m_temp_%s.csv
                        KITDEATHS%Y-%m_MBIS.zip].
                     collect { |s| 'extracts/KIT Annual Extracts/KITDEATHS/%Y-%m-%d/' + s }
    date, (fname, fname_sum, fname_tmp,
           fname_zip), batches = Export::Helpers::RakeHelper::DeathExtractor.
                                 pick_mbis_monthly_death_batches('KITDEATHS', fname_patterns)
    unless batches
      puts 'No batch selected - aborting.'
      exit
    end
    fname_full = SafePath.new('mbis_data').join(fname)
    fname_tmp_full = SafePath.new('mbis_data').join(fname_tmp)
    batches.each_with_index do |eb, i|
      # Extract subsequent batches to a temporary file, then concatenate to the first file
      Export::Helpers::RakeHelper::DeathExtractor.
        extract_mbis_weekly_death_file(eb, i.zero? ? fname : fname_tmp,
                                       'Export::KitDeathsFile')
      unless i.zero?
        # Skip header row when appending
        File.open(fname_full, 'a') { |f| f << File.read(fname_tmp_full).split("\r\n", 2)[1] }
        FileUtils.rm(fname_tmp_full)
      end
    end
    # Generate summary report file
    counts = { 'KITDEATHS' => CSV.read(fname_full).size - 1 }
    group_names = { 'KITDEATHS' => 'KITDEATHS EXTRACT' }
    File.open(SafePath.new('mbis_data').join(fname_sum), 'w+') do |f|
      group_names.each do |group, name|
        lines = [' ', "#{recipient} MONTHLY #{name} REPORT",
                 "DATE OF RUN: #{date.strftime('%Y%m%d')}",
                 "RECORDS SENT TO #{recipient} THIS MONTH    :     #{counts[group] || 0}"]
        lines.each { |l| f << l + "\r\n" }
      end
    end
    Export::Helpers::RakeHelper::EncryptOutput.
      compress_and_encrypt_zip(pdp, 'extracts/KIT Annual Extracts/KITDEATHS',
                               fname_zip, fname, fname_sum)
    puts "Created extract file #{fname_zip}"
  end
end
