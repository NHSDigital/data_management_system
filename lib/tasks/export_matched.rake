namespace :export do
  # TODO: Support extract of matched records from MBIS (e.g. non-cancer deaths)
  # TODO: Support extract of matched records from Prescriptions data (with de-pseudonymising option)
  # TODO: Support extract of matched records from BRCA data (with de-pseudonymising option)
  # TODO: Allow extraction of _latest_ record instead of first record for each patient.
  # TODO: Allow automatic encryption of the output
  desc <<-EOT
Export matched MBIS data (matching by exact NHS number and date of birth)
Syntax: rake export:matched [infile=demog.csv] [outfile=creg_data.ncr] \\
        e_type=PSDEATH klass=Export::CancerDeathWeekly [verbose=true] [allow_fuzzy=true]
allow_fuzzy options: true / veryfuzzy / fuzzy / fuzzy_postcode / perfect / false / none
                     or comma-separated combinations, e.g. fuzzy,fuzzy_postcode
infile (or stdin) is a CSV of rowid,nhsnumber,birthdate,postcode
e.g.: 12345,9999999468,1925-01-27,B6 5RQ
EOT
  task matched: [:environment, 'pseudo:keys:load'] do
    infile = if ENV['infile']
               File.open(SafePath.new('mbis_data').join(ENV['infile']), 'r')
             else
               puts <<-EOT if $stdin.tty?
Enter CSV data, ^D to finish. For syntax: rake -D match:demographics
  #{Pseudo::Match::DelimitedFile::HEADER_ROW.join(',')}
  12345,9999999468,1925-01-27,B6 5RQ\n
               EOT
               $stdin
             end
    raise('Expected outfile') if ENV['outfile'].blank?
    fname = SafePath.new('mbis_data').join(ENV['outfile'])
    e_type = ENV['e_type']
    raise 'Expected parameter e_type' unless e_type
    key_names = ENV['key_names'] ? ENV['key_names'].split(',') : nil
    logger = ENV['verbose'] ? ActiveSupport::Logger.new($stdout) : nil
    match_scores = Pseudo::RakeHelper::MatchDemographics.
                   expand_allow_fuzzy_options(ENV['allow_fuzzy'])
    klass = ENV['klass'].constantize # e.g. Export::DelimitedFile, Export::CancerMortalityFile
    matches = Pseudo::Match::Ppatients.new([e_type], key_names, logger).
              match(infile, match_scores) # list of [pseudo_id1, rowid, ppatientid, match_status]
    ppatids = matches.collect(&:third)
    ppatid_rowids = Hash[matches.collect { |m| [m[2], m[1]] }]
    puts "Found #{ppatids.count} matching patient records to extract"
    if ppatids.empty?
      puts 'Warning: nothing to extract, not creating empty output file'
      exit
    end
    # Workaround for Rails 5.2.1 issue with long lists (over 65535 entries) in prepared statements
    # https://github.com/rails/rails/pull/33844
    # https://github.com/kamipo/rails/commit/b571c4f3f2811b5d3dc8b005707cf8c353abdf03
    # https://github.com/rails/rails/issues/33702
    # ppats = Pseudo::Ppatient.where(id: ppatids)
    slices = ppatids.each_slice(65535).to_a
    ppats = Pseudo::Ppatient.where(slices.collect { 'id in (?)' }.join(' or '), *slices)
    i = klass.new(fname, e_type, ppats, ENV['filter'], ppatid_rowids: ppatid_rowids).export
    puts "Created #{fname} with #{i} entries" if fname && $stdout.tty?
  end
end
