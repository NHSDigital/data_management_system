# Re-pseudonymise prescription data files, in ruby.
# Turns each SHA-256 pseudo_id1 / pseudo_id2 / pseudo_id column
# into a rehashed version:

# The recomputed hash is data_hash('pseudoid_'  + old_pseudo_id, salt_repseudo)
# where old_pseudo_id must be a 64 character SHA-256 hash (in lowercase hex),
# and salt_repseudo is a 64 character random salt (in lowercase hex)
# and data_hash is the SHA-256 hash (in lowercase hex)

# The recomputed hash is by default shortened (truncated) to the first 16 hex characters only

require 'csv'
require 'digest/sha2'

unless [3, 4].include?(ARGV.size)
  puts 'Error: Missing argument'
  puts 'Syntax: ruby ndr_repseudonymise.rb csv_in.csv csv_out.csv salt_repseudo [shorten=false]'
  exit 1
end

infile = ARGV[0]
outfile = ARGV[1]
salt_repseudo = ARGV[2]
shorten = !ARGV[3]&.start_with?('shorten=f') # shorten by default

unless File.exist?(infile)
  puts "Error: Missing input file: #{infile}"
  exit 1
end

hash_re = /\A[0-9a-f]{64}\z/

unless hash_re.match?(salt_repseudo)
  puts 'Error: Invalid salt_repseudo'
  exit 1
end

def data_hash(value, salt)
  Digest::SHA2.hexdigest(value.to_s + salt.to_s)
end

change_cols = nil # List of column numbers to re-pseudonymise
rownum = 0
CSV.open(outfile, 'wb') do |csv_out|
  CSV.foreach(infile) do |row|
    rownum += 1
    if rownum == 1 # Header row
      change_cols = row.collect.with_index do |col, index|
        index if col.match?(/pseudo_id[_0-9]*/i)
      end.compact
      if change_cols.empty?
        STDERR << "Error: no columns to repseudonymise\n"
        exit 1
      end
      STDERR << "Re-pseudonymising columns #{change_cols.collect { |i| row[i] }}\n"
      change_cols.each { |i| row[i] += '_short' } if shorten
    else
      change_cols.each do |i|
        next if row[i].nil? || row[i] == ''
        unless row[i].match?(hash_re)
          STDERR << "Error: invalid pseudo_id on row #{rownum}, column offset #{index}: aborting\n"
          exit 1
        end
        row[i] = data_hash("pseudoid_#{row[i]}", salt_repseudo) # Re-pseudonymise
        row[i] = row[i][0..15] if shorten
      end
    end
    csv_out << row
  end
end
