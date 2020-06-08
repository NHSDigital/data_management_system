require 'highline/import'

def pick_mbis_annual_subset_batch(desc, fname_patterns, e_type)
  annual_re = /subset.*([12][0-9]{3})/i
  dated_batches = EBatch.where('e_type = ? and lower(original_filename) like ?',
                               e_type, '%subset%').collect do |eb|
    next unless annual_re =~ eb.original_filename
    date = Date.strptime(Regexp.last_match[1], '%Y')
    [date, fname_patterns.collect { |s| date.strftime(s) }, eb]
  end.compact.sort
  puts "e_batchid: original MBIS filename -> #{desc} files"
  dated_batches.each do |date, fnames, eb|
    next unless date >= 20.years.ago
    puts format('%-9d: %s -> %s', eb.id, Pathname.new(eb.original_filename).basename.to_s,
                fnames[0..1].join(', '))
  end
  print 'Choose e_batchid to export: '
  e_batchid = STDIN.readline.chomp.to_i
  date, fnames, eb = dated_batches.find { |_, _, eb2| eb2.id == e_batchid }
  fnames.each { |fname| raise "Not overwriting existing #{fname}" if File.exist?(fname) }
  [date, fnames, eb]
end

def extract_mbis_file(e_batch, fname, klass, filter = nil)
  puts "Extracting #{fname}..."
  system('rake', e_batch.e_type == 'PSDEATH' ? 'export:death' : 'export:birth', "fname=#{fname}",
         "original_filename=#{e_batch.original_filename}", "klass=#{klass}", "filter=#{filter}")
  File.exist?(fname)
end

namespace :export do
  desc 'Export MEPH (Materneties) annual files interactively'
  task meph: [:environment, 'pseudo:keys:load'] do
    # Check keys are correctly configured
    fname_patterns = (1..4).collect { |i| "MEPH%y#{i}_MBIS.TXT" }
    _date, fnames, eb = pick_mbis_annual_subset_batch('MEPH', fname_patterns, 'PSBIRTH')
    unless eb
      puts 'No batch selected - aborting.'
      exit
    end
    fnames.each_with_index do |fname, i|
      unless extract_mbis_file(eb, fname, 'Export::MaternitiesFile', i + 1)
        puts "Error: failed to extract #{fname} - aborting."
        exit 1
      end
    end
    tot = fnames.collect { |fname| File.readlines(fname).size - 1 }.sum
    # Add total to 4th quarter file
    File.open(fnames[-1], 'a') do |f|
      f << [nil, "TOTAL RECORDS EXTRACTED FOR YEAR = #{tot}"].pack('A55A55') + "\r\n"
    end
    # TODO: Password generated with: openssl rand 16 -hex
    # TODO: 7za a -p -mx=9 -mm=Deflate -mem=AES256 -tzip 2018-01-13/HPAMTH2018-01_MBIS.zip 2018-01-13/*.TXT -sdel
    puts "Extracted files #{fnames.join(', ')}"
  end
end
