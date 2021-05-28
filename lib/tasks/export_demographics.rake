namespace :export do
  desc <<~USAGE
    Export matched demographics (matching by exact NHS number, or postcode and date of birth)
    Syntax: rake export:matched [infile=demog.csv] [outfile=creg_data.ncr] \\
            e_type=PSDEATH [verbose=true] [allow_fuzzy=true] [extract_fields=nhsnumber,birthdate]
    allow_fuzzy options: true / veryfuzzy / fuzzy / fuzzy_postcode / perfect / false / none
                         or comma-separated combinations, e.g. fuzzy,fuzzy_postcode
    infile (or stdin) is a CSV of rowid,nhsnumber,birthdate,postcode
    e.g.: 12345,9999999468,1925-01-27,B6 5RQ

    Produces an output CSV file with columns:
    rowid,nhsnumber,birthdate,postcode,match_status,ppatient_id,original_filename,demographics_json
  USAGE
  task demographics: [:environment, 'pseudo:keys:load'] do
    if ENV['outfile'].blank? || ENV['e_type'].blank?
      system('DISABLE_SPRING=1 bin/rake -D export:demographics$') # Print usage
      exit(1)
    end
    infile = if ENV['infile']
               File.open(SafePath.new('mbis_data').join(ENV['infile']), 'r')
             else
               puts <<~EXAMPLE if $stdin.tty?
                 Enter CSV data, ^D to finish. For syntax: rake -D export:demographics
                   #{Pseudo::Match::DelimitedFile::HEADER_ROW.join(',')}
                   12345,9999999468,1925-01-27,B6 5RQ\n
               EXAMPLE
               $stdin
             end
    raise('Expected outfile') if ENV['outfile'].blank?

    fname = SafePath.new('mbis_data').join(ENV['outfile'])
    e_type = ENV['e_type']
    raise 'Expected parameter e_type' unless e_type

    key_names = ENV['key_names'] ? ENV['key_names'].split(',') : nil
    # TODO: Allow variable verbosity, e.g. warn vs info
    logger = ENV['verbose'] ? ActiveSupport::Logger.new($stdout) : nil
    match_scores = Pseudo::RakeHelper::MatchDemographics.
                   expand_allow_fuzzy_options(ENV['allow_fuzzy'])
    extract_fields = ENV['extract_fields'].to_s.split(',')
    Pseudo::RakeHelper::MatchDemographics.export_demographics(infile: infile, outfname: fname,
                                                              e_types: [e_type],
                                                              key_names: key_names,
                                                              logger: logger,
                                                              match_scores: match_scores,
                                                              extract_fields: extract_fields)
  end
end
