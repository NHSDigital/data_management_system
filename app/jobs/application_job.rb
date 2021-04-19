# -
class ApplicationJob < ActiveJob::Base
  private

  def log(message)
    Rails.logger.info(message)
  end

  # Puts the job back on the queue for later
  def reschedule_for(wait_until)
    self.class.set(wait_until: wait_until).perform_later
    log("[#{self.class.name}] Rescheduled for #{wait_until}")
  end
end
