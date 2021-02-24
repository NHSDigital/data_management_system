unless ENV['NO_COVERAGE']
  require 'simplecov'
  # ignore the test directory
  SimpleCov.start do
    add_filter '/test/'
    add_filter '/vendor/'
    add_filter '/config/'
    add_filter '/lib/import/'
    add_filter '/lib/export/'
  end
end

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

ENV['INTEGRATION_DRIVER'] ||= 'chrome_headless'
require 'ndr_dev_support/integration_testing'

require 'pry'
require 'capybara/email'
require 'create_records_helper'

require_relative 'download_helpers'

Capybara.server = :puma, { Silent: true }

# When running in parallel, there can be occassional chokes, so this accounts for that.
# This shouldn't slow down tests that are well-written.
Capybara.default_max_wait_time = 10.seconds

# Devise support for functional / integration test
module ActionDispatch
  class IntegrationTest
    # Ensure functional & integration tests play nicely with devise:
    include Devise::Test::IntegrationHelpers

    # Allow capybara to interact with emails
    include Capybara::Email::DSL
    include ActionMailer::TestHelper

    # Support for testing file downloads
    include DownloadHelpers

    setup do
      clear_headless_session!
      clear_emails
    end

    # Configure ActionMailer url helpers with test server details:
    setup do
      @capybara_server ||= Capybara.current_session.server
      config = { host: @capybara_server.host, port: @capybara_server.port }
      ActionMailer::Base.default_url_options.merge!(config)
    end

    setup do
      # Trigger a just-in-time recompile, before any integration tests start running,
      # and fail due to waiting. Returns immediately on subsequent calls.
      Webpacker.compile
    end

    teardown { Capybara.reset_sessions! }

    # In the integration test environment, rather than trying to share a connection
    # (and thus transaction) between the test process and the tested process, use
    # the database_cleaner gem. This avoids non-deterministic failures seen with
    # the former approach, and should probably be moved upstream into ndr_dev_support.
    # self.use_transactional_tests = false
    # setup { DatabaseCleaner.start }
    # teardown { DatabaseCleaner.clean }

    def fill_in_team_data
      fill_in 'team_name', with: 'Test Team'
      select 'Directorate 1', from: 'team_directorate_id'
      select 'Division 1 from directorate 1', from: 'team_division_id'

      fill_in 'team_notes', with: 'Some interesting notes about this project'
    end

    # Use to pre-fill http_basic credentials:
    def use_basic_auth(user)
      otpw = user.yubikey ? user.yubikey + 'ginlcnfebblntbitntgctrvgihirrlfc' : ''

      # Simulate HTTP_BASIC credentials being supplied:
      ApplicationController.any_instance.stubs(
        http_basic_username: user.username,
        http_basic_otpw:     otpw
      )
    end
  end
end

def bootstrap_download_helper
  DownloadHelpers.create_directory

  chrome = Capybara.drivers[:chrome]
  Capybara.register_driver(:chrome) do |app|
    chrome.call(app).tap do |driver|
      driver.browser.download_path = DownloadHelpers.directory
    end
  end

  Capybara.register_driver :chrome_headless do |app|
    Capybara::Selenium::Driver.load_selenium
    browser_options = ::Selenium::WebDriver::Chrome::Options.new.tap do |opts|
      opts.args << '--headless'
      opts.args << '--disable-gpu' if Gem.win_platform?
      opts.args << '--no-sandbox'
      # Workaround https://bugs.chromium.org/p/chromedriver/issues/detail?id=2650&q=load&sort=-id&colspec=ID%20Status%20Pri%20Owner%20Summary
      opts.args << '--disable-site-isolation-trials'
      opts.args << '--window-size=1920,1080'
      opts.args << '--enable-features=NetworkService,NetworkServiceInProcess'
    end

    # Chrome >= 77
    browser_options.add_preference(:download, default_directory: DownloadHelpers.directory)

    Capybara::Selenium::Driver.new(app, browser: :chrome, options: browser_options).tap do |driver|
      # Chrome < 77
      driver.browser.download_path = DownloadHelpers.directory
    end
  end
end

# Bootstrap for the single process case:
bootstrap_download_helper

# Ensure the driver is installed in advance of any parallel testing.
Webdrivers::Chromedriver.update

module ActiveSupport
  class TestCase
    # Something about MBIS doesn't like parallel testing. Very noticeable on the CI
    # platform, occassionally also developing locally. For now, will disable parallel
    # testing unless the `PARALLEL_WORKERS` variable is explicitly set.
    parallelize(workers: :number_of_processors)

    # Re-bootstrap for the multi process case:
    parallelize_setup do
      DownloadHelpers.remove_directory
      DownloadHelpers.create_directory

      bootstrap_download_helper
    end

    parallelize_teardown do
      DownloadHelpers.remove_directory
    end

    # Required for testing when using devise
    # include Devise::Test::ControllerHelpers

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all
    include CreateRecordsHelper

    def login_and_accept_terms(user)
      sign_in user
      visit terms_and_conditions_path
      click_on 'Accept'
    end

    def within_row(text)
      within :xpath, "//table//tr[td[contains(.,\"#{text}\")]]" do
        yield
      end
    end

    require 'mocha/mini_test'
  end
end

def empty_schema(output)
  schema = ::Builder::XmlMarkup.new(target: output, indent: 2)
  schema.instruct!
  schema
end

# Adds some PaperTrail based helpers and assertions.
module PaperTrailHelper
  # Allow auditing to be temporarily enabled for a test case.
  def with_versioning
    was_enabled = PaperTrail.enabled?
    was_enabled_for_controller = PaperTrail.request.enabled?
    PaperTrail.enabled = true
    PaperTrail.request.enabled = true
    begin
      yield
    ensure
      PaperTrail.enabled = was_enabled
      PaperTrail.request.enabled = was_enabled_for_controller
    end
  end

  # Asserts that PaperTrail is enabled on `object`
  def assert_auditable(object, message = nil)
    klass = object.is_a?(Class) ? object : object.class
    message ||= "PaperTrail disabled for #{klass}"
    assert PaperTrail.request.enabled_for_model?(klass), message
  end

  # Inverse of assert_auditable
  def refute_auditable(object, message = nil)
    klass = object.is_a?(Class) ? object : object.class
    message ||= "PaperTrail enabled for #{klass}"
    refute PaperTrail.request.enabled_for_model?(klass), message
  end
end

ActiveSupport::TestCase.include(PaperTrailHelper)
ActionDispatch::IntegrationTest.include(PaperTrailHelper)

# Ensure NdrUi::Bootstrap helper methods are available in helper tests.
ActionView::TestCase.helper NdrUi::BootstrapHelper
