# This file contains production configuration for puma.
require 'puma/daemon'

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
min_threads_count = ENV.fetch('RAILS_MIN_THREADS', 5)
max_threads_count = ENV.fetch('RAILS_MAX_THREADS', 5)
threads min_threads_count, max_threads_count

# Accept requests from:
bind "tcp://0.0.0.0:#{ENV.fetch('PUMA_PORT', 5001)}"

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked web server processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
workers ENV.fetch('WEB_CONCURRENCY', 10)

# Increased timeouts to prevent "Terminating timed out worker" messages in puma-stdout
worker_timeout 200

# Stops a hanging request preventing a cluster restart.
# Raises a Puma::ThreadPool::ForceShutdown in the worker.
force_shutdown_after 10

# Workers busy handling requests wait to give idle workers a chance to handle them
# wait_for_less_busy_worker # NOTE: Puma >= 5.x

# Dump all stacks when shutdown is requested; to help
# with debugging if threads are stuck.
shutdown_debug

# Accept commands from:
# NOTE: puma responds to signals: https://github.com/puma/puma/blob/master/docs/signals.md
# activate_control_app 'tcp://0.0.0.0:2999', { no_token: true }

# Daemonizing:
daemonize
pidfile 'tmp/pids/puma.pid'
stdout_redirect 'log/puma-stdout', 'log/puma-stderr', true

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
#
# preload_app!

# Sets RACK_ENV, which otherwise defaults to "development" [#8224]
#
# Still need to export RAILS_ENV explicitly, otherwise Rails will try
# and boot in a non-existent "deployment" environment.
environment 'deployment'

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart
