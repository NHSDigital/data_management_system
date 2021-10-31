namespace :import do
  desc <<~SYNTAX
    Import all weekly MBIS Birth / Death data
    Usage:
      bin/rake import:weekly [e_types=PSBIRTH,PSDEATH]
      Use a comma separated list of e_types

      Returns an exit status of 0 on successful import, or 1 if imports fail
  SYNTAX
  task weekly: [:environment, 'pseudo:keys:load'] do
    e_types = ENV['e_types'].presence&.split(',') || %w[PSBIRTH PSDEATH]
    logger = ActiveSupport::Logger.new($stdout)
    logger.extend(ActiveSupport::Logger.broadcast(Rails.logger))
    begin
      count = Import::Helpers::RakeHelper::FileImporter.import_weekly(e_types, logger: logger)
      if count.zero?
        logger.warn "No new weekly batches to import for e_types=#{e_types.join(',')}"
        unless ENV['quieter_import_weekly']
          # Allow extra messages to be silenced, e.g. when running from inside rake export:weekly
          logger.warn 'For annual or unusually named batches, use bin/rake import:birth ' \
                      'or bin/rake import:death'
        end
      else
        logger.warn "Imported #{count} batches for e_types #{e_types.join(',')}"
      end
      # TODO: Warn about what to do for exceptions
    rescue RuntimeError => e
      unless [e.message, e.cause&.message].any? do |message|
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
