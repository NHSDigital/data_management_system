namespace :match do
  desc <<-EOT
Identify Ppatient records with matching demographics
Syntax: rake match:demographics [infile=demog.csv] [outfile=matched_ids.csv] \\
        [e_types=PSPRESCRIPTION,PSDEATH] [key_names=key1,key2] [verbose=true]
  EOT
  task demographics: :environment do
    infile = if ENV['infile']
               File.open(SafePath.new('prescr_data').join(ENV['infile']), 'r')
             else
               puts <<-EOT if $stdin.tty?
Enter CSV data, ^D to finish. For syntax: rake -D match:demographics
  #{Pseudo::Match::DelimitedFile::HEADER_ROW.join(',')}
  12345,9999999468,1925-01-27,B6 5RQ\n
               EOT
               $stdin
             end
    outfile = ENV['outfile'] ? File.open(ENV['outfile'], 'w') : $stdout
    e_types = ENV['e_types'] ? ENV['e_types'].split(',') : nil
    key_names = ENV['key_names'] ? ENV['key_names'].split(',') : nil
    Pseudo::Ppatient.keystore = Pseudo::KeyStoreLocal.new(Pseudo::KeyBundle.new)
    logger = ENV['verbose'] ? ActiveSupport::Logger.new($stdout) : nil
    Pseudo::Match::DelimitedFile.new(infile, outfile, e_types, key_names, logger).match
    puts "Created ENV['outfile']" if ENV['outfile'] && $stdout.tty?
  end
end
