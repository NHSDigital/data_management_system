module Mbis
  class << self
    def stack
      @stack ||= derive_stack
      ActiveSupport::StringInquirer.new(@stack)
    end

    private

    def derive_stack
      if Rails.env.production?
        stacks  = %w[beta live]
        selection = ENV.fetch('STACK', stacks.first).downcase

        unless selection.in?(stacks)
          raise "Unknown stack! '#{selection}' is not in known list: #{stacks}"
        end

        selection
      else
        Rails.env
      end
    end
  end
end

Rails.application.config.after_initialize do
  Rails.logger.info("Detected as running stack: #{Mbis.stack}")
end
