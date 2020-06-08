# Helper methods for testing file downloads, lovingly copied from:
# https://collectiveidea.com/blog/archives/2012/01/27/testing-file-downloads-with-capybara-and-chromedriver
#
# TODO: upstream this into ndr_dev_support, including configuring the drivers
module DownloadHelpers
  extend ActiveSupport::Concern

  class << self
    def directory
      @directory || raise('Directory not created!')
    end

    def create_directory
      @directory ||= Pathname.new(Dir.mktmpdir)
    end

    def remove_directory
      FileUtils.remove_entry(directory, true)
      @directory = nil
    end
  end

  included do
    setup { DownloadHelpers.create_directory }
    teardown { clear_downloads }
  end

  def downloads
    Dir[DownloadHelpers.directory.join('*')]
  end

  def download
    downloads.first
  end

  def download_content
    wait_for_download
    File.read(download)
  end

  # Use `using_wait_time { ... }` to wait for longer.
  def wait_for_download
    attempts     = 0
    poll         = 0.1
    seconds      = Capybara.default_max_wait_time
    max_attempts = seconds / poll

    while attempts < max_attempts
      return if downloaded?

      attempts += 1
      sleep(poll)
    end

    raise "Waited #{seconds} for download, without success!"
  end

  def downloaded?
    !downloading? && downloads.any?
  end

  def downloading?
    downloads.grep(/\.crdownload$/).any?
  end

  def clear_downloads
    FileUtils.rm_f(downloads)
  end
end
