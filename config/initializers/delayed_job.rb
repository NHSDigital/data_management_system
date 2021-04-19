Delayed::Worker.tap do |worker|
  worker.destroy_failed_jobs = false
  worker.sleep_delay  = 60.seconds
  worker.max_attempts = 5
end
