require 'test_helper'

# This module provides support methods for integration tests
module IntegrationTestHelper
  extend ActiveSupport::Concern

  included do
    # Ensure that tests do not leave extra windows open, polluting other tests.
    teardown do
      next if windows.count <= 1

      raise "Error: test left extra windows open: windows.count = #{windows.count}"
    end
  end

  # Manually wait for AJAX requests in integration tests, for clarity.
  def wait_for_ajax
    started_waiting_at = Time.current
    while page.evaluate_script('jQuery.active').positive?
      break if (Time.current - started_waiting_at) > Capybara.default_max_wait_time

      sleep 0.01
    end
  end

  # Safely sign in as a different user within a test
  def change_sign_in(resource, scope: nil)
    wait_for_ajax
    sign_in(resource, scope: scope)
  end
end
