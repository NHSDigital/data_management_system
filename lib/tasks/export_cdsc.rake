require 'highline/import'

namespace :export do
  desc 'Export CDSC weekly files interactively'
  task cdsc: [:environment, 'pseudo:keys:load'] do
    week = ENV.delete('week')
    # Check keys are correctly configured
    pdp = Export::Helpers::RakeHelper::EncryptOutput.find_project_data_password(
      'Weekly CDSC extract', 'Information Management'
    )
    fname_patterns = %w[CDSCWK%W_MBIS.TXT CDSC9WK%W_MBIS.TXT CDSCPRINTWK%W_MBIS.TXT
                        CDSC%Y%m%d_MBIS.zip].
                     collect { |s| 'extracts/CDSC Weekly/%Y-%m-%d/' + s }
    date, (fn_not9, fn9, fn_sum, fn_zip), eb = Export::Helpers::RakeHelper::DeathExtractor.
                                               pick_mbis_weekly_death_batch('CDSC', fname_patterns,
                                                                            week: week)
    unless eb
      puts 'No batch selected - aborting.'
      exit
    end
    to_extract = [[fn_not9, 'Export::CdscWeeklyNot9'], [fn9, 'Export::CdscWeekly9']]
    to_extract.each do |fname, klass|
      unless Export::Helpers::RakeHelper::DeathExtractor.
             extract_mbis_weekly_death_file(eb, fname, klass)
        puts "Error: failed to extract #{fname} - aborting."
        exit 1
      end
    end
    # Generate summary report file
    surveillances = to_extract.collect do |fname, _|
      CSV.read(SafePath.new('mbis_data').join(fname)).collect(&:last)
    end.flatten
    counts = surveillances.group_by { |x| x }.collect { |k, v| [k, v.size] }.to_h
    group_names = { 'CDSC01' => 'ICD10 MENINGITIS:SURVEILLANCE CODE',
                    'CDSC02' => 'ICD10 Vaccine preventables:SURVEILLANCE CODE',
                    'CDSC03' => 'ICD10 HIV - STI:SURVEILLANCE CODE',
                    'CDSC04' => 'ICD10 Respiratory:SURVEILLANCE CODE',
                    'CDSC05' => 'ICD10 Streptococcal bacteraemias:SURVEILLANCE CODE',
                    'CDSC06' => 'ICD10 Gastrosurveillance:SURVEILLANCE CODE',
                    'CDSC07' => 'ICD10 Travel zoonosis: SURVEILLANCE CODE',
                    'CDSC08' => 'ICD10 Other',
                    'CDSC09' => 'ICD10 J180 to J219',
                    'CDSC10' => 'ICD10 J09 Swine flu' }
    File.open(SafePath.new('mbis_data').join(fn_sum), 'w+') do |f|
      group_names.each do |group, name|
        lines = [' ', "#{name} = #{group} WEEKLY REPORT",
                 "DATE OF RUN: #{date.strftime('%Y%m%d')}",
                 "RECORDS SENT TO CDSC THIS WEEK: #{counts[group] || 0}"]
        lines.each { |l| f << l + "\r\n" }
      end
    end
    Export::Helpers::RakeHelper::EncryptOutput.
      compress_and_encrypt_zip(pdp, 'extracts/CDSC Weekly',
                               fn_zip, *to_extract.collect(&:first), fn_sum)
    puts "Created extract file #{fn_zip}"
  end
end

namespace :export do
  desc 'Export Cancer Death (CD) weekly files interactively'
  task cd: [:environment, 'pseudo:keys:load'] do
    week = ENV.delete('week')
    klass = Export::CancerDeathWeekly
    filter = 'cd'
    # Check keys are correctly configured
    pdp = Export::Helpers::RakeHelper::EncryptOutput.find_project_data_password(
      'EnCORE Mortality Data Feed', 'ENCORE'
    )
    recipient = 'CD'
    fname_patterns = klass.fname_patterns(filter, :weekly).
                     collect { |s| 'extracts/CD Weekly/%Y-%m-%d/' + s }
    date, (fname, fn_sum,
           fn_zip), eb = Export::Helpers::RakeHelper::DeathExtractor.
                         pick_mbis_weekly_death_batch(recipient, fname_patterns, week: week)
    unless eb
      puts 'No batch selected - aborting.'
      exit
    end
    fname_full = SafePath.new('mbis_data').join(fname)
    unless Export::Helpers::RakeHelper::DeathExtractor.
           extract_mbis_weekly_death_file(eb, fname, klass, filter)
      puts "Error: failed to extract #{fname} - aborting."
      exit 1
    end
    # Generate summary report file
    # Ignore 1 header row in computing count
    counts = { 'CD' => CSV.read(fname_full).size - 1 }
    group_names = { 'CD' => 'Cancer deaths' }
    File.open(SafePath.new('mbis_data').join(fn_sum), 'w+') do |f|
      group_names.each do |group, name|
        lines = [' ', "#{name} = #{group} WEEKLY REPORT",
                 "DATE OF RUN: #{date.strftime('%Y%m%d')}",
                 "RECORDS SENT TO #{recipient} THIS WEEK: #{counts[group] || 0}"]
        lines.each { |l| f << l + "\r\n" }
      end
    end
    Export::Helpers::RakeHelper::EncryptOutput.
      compress_and_encrypt_zip(pdp, 'extracts/CD Weekly',
                               fn_zip, fname, fn_sum)
    puts "Created extract file #{fn_zip}"
  end
end

namespace :export do
  desc 'Export flu / pandemic (PAN) weekly files interactively'
  task flu: [:environment, 'pseudo:keys:load'] do
    week = ENV.delete('week')
    # Check keys are correctly configured
    recipient = 'FLU'
    pdp = Export::Helpers::RakeHelper::EncryptOutput.find_project_data_password(
      'PHE mortality surveillance', 'Influenza Surveillance'
    )
    fname_patterns = %w[PAN%y%m%d_MBIS.TXT PAN%y%m%d_MBIS.zip].
                     collect { |s| 'extracts/Pandemic Flu Weekly Extract/%Y-%m-%d/' + s }
    _date, (fname, fn_zip), eb = Export::Helpers::RakeHelper::DeathExtractor.
                                 pick_mbis_weekly_death_batch(recipient, fname_patterns, week: week)
    unless eb
      puts 'No batch selected - aborting.'
      exit
    end
    unless Export::Helpers::RakeHelper::DeathExtractor.
           extract_mbis_weekly_death_file(eb, fname, 'Export::PandemicFluWeekly')
      puts "Error: failed to extract #{fname} - aborting."
      exit 1
    end
    Export::Helpers::RakeHelper::EncryptOutput.
      compress_and_encrypt_zip(pdp, 'extracts/Pandemic Flu Weekly Extract',
                               fn_zip, fname)
    puts "Created extract file #{fn_zip}"
  end
end
