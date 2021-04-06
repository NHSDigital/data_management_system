require File.expand_path('../../config/application', __FILE__)

require 'optparse'
require 'pry'
#require 'import/central_logger'
#require 'import/utility/pseudonymised_file_wrapper'

# This is run as a standalone, so it does not tie in to the central logger
logger = Import::Log.get_auxiliary_logger
options = { mode: :pretty_write,
            direction: :horizontal,
            include_name: true,
            comparison_mode: false }
OptionParser.new do |opts|
  opts.banner = 'Usage; pseudonymised_file_converter <filenames> [options]'
  opts.on('-f',
          '--fields',
          'Report available fields') { options[:mode] = :report_fields }
  opts.on('-v',
          '--vertical',
          'Report available fields vertically') { options[:direction] = :vertical }
  opts.on('-n',
          '--no-name',
          'Exclude filename in horizontal printing') { options[:include_name] = false }
  opts.on('-c',
          '--comare-fields',
          'Figure out available filds') { options[:comparison_mode] = true }
  opts.on('-b', '--batch x y z', Array, 'Not yet implemented!') do |list|
    options[:files] = list
  end
end.parse!

raise 'No filename provided' unless ARGV

if options[:comparison_mode]
  results = {}
  (ARGV + STDIN.readlines.map(&:strip)).each do |file|
    fw = Import::Utility::PseudonymisedFileWrapper.new(file)
    fw.process
    results[file] = fw.available_fields
  end

  common_fields = results.map { |_k, v| v }.inject(:&)
  logger.debug 'Common fields: '
  common_fields.each do |field|
    logger.debug "\t#{field}"
  end

  files_and_fields = results.map { |k, v| [k, v - common_fields] }

  files_and_fields.chunk { |_k, v| v } .each do |_k, v|
    logger.debug '********* Field Chunk *********'
    if v[0][0]
      v[0][1].each do |field|
        logger.debug "\t#{field}"
      end
    end

    logger.debug ''
    v.each do |file, _fields|
      logger.debug "\t#{file}"
    end
    logger.debug ''
  end
else
  ARGV.each do |file|
    logger.debug file
    logger.debug file.class
    fw = Import::Utility::PseudonymisedFileWrapper.new(file)
    fw.process
    case options[:mode]
    when :pretty_write
      fw.pretty_write
    when :report_fields
      case options[:direction]
      when :horizontal
        logger.debug "#{file if options[:include_name]}: #{fw.available_fields.sort}"
      when :vertical
        logger.debug "#{file}: "
        fw.available_fields.sort.each do |field|
          logger.debug "\t#{field}"
        end
      end
    end
  end
end

# *************** Read in the file, parsing and recording fields in each line **************
