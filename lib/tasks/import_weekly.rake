namespace :import do
  desc <<~SYNTAX
    Import all weekly MBIS Birth / Death data
    Usage:
      bin/rake import:weekly [e_types=PSBIRTH,PSDEATH]
      Use a comma separated list of e_types
  SYNTAX
  task weekly: [:environment, 'pseudo:keys:load'] do
    e_types = ENV['e_types'].presence&.split(',') || %w[PSBIRTH PSDEATH]
    logger = ActiveSupport::Logger.new($stdout)
    logger.extend(ActiveSupport::Logger.broadcast(Rails.logger))
    # TODO: Make weekly import / export return an exit status
    # TODO: Make general weekly import import everything if you don't give a filename
    # TODO: Put pointers into exception catching
    begin
      count = Import::Helpers::RakeHelper::FileImporter.import_weekly(e_types, logger: logger)
      if count.zero?
        logger.warn "No new weekly batches to import for e_types=#{e_types.join(',')}"
        logger.warn 'For annual or unusually named batches, use bin/rake import:birth ' \
                    'or bin/rake import:death'
      else
        logger.warn "Imported #{count} batches for e_types #{e_types.join(',')}"
      end
      # TODO: Warn about what to do for exceptions
    rescue RuntimeError => e
      unless [e.message, e.cause.message].any? do |message|
               ['ERROR: failure importing file',
                'ERROR: Not importing file with missing footer row - possibly truncated?'].
             include?(message)
             end
        logger.warn 'To import batches individually, use bin/rake import:birth ' \
                    'or bin/rake import:death'
        raise
      end
      # Don't show backtrace for common, self-explanatory errors
      puts "#{e.class} #{e}"
      puts "#{e.cause.class} #{e.cause}" if e.cause
      exit 1
    end
  end
end
