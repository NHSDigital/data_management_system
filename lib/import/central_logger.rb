require 'date'
require 'logger'
module Import
  # Provide convenient access to a centralized logger instance
  class Log
    def self.get_logger(filename = '', provider = '')
      if @logger.nil?
        file_ref = File.basename(filename, '.xlsx.pseudo')
        # TODO: this logfile naming/accessing method is somewhat dangerous, as it requires
        #       that the first call comes from the correct file. Should be made more robust
        @logger = Logger.new(
          File.new(
            "log/#{DateTime.current.strftime('%Y%m%d_%H%M_%z')}_#{provider}_#{file_ref}.log",
            'w'
          )
        )
        @logger.level = Logger::DEBUG
        @logger.formatter = proc do |sev, date_time, _name, message|
          puts "(#{sev}) #{message}"
          "#{date_time} (#{sev}): #{message}\n"
        end
      end
      @logger
    end

    # Gets the main logger if it's active, otherwise dumps to stdout
    def self.get_auxiliary_logger
      return @logger if @logger

      Logger.new(STDOUT)
    end
  end
end
