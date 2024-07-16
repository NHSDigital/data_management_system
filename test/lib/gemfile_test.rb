require 'test_helper'

class GemfileTest < ActiveSupport::TestCase
  EXPECTED_MINI_RACER_ROWS = <<-TXT.freeze
    mini_racer (0.12.0)
      libv8-node (~> 21.7.2.0)
    mini_racer (0.12.0-x86_64-linux)
      libv8-node (~> 21.7.2.0)
  TXT
  test 'Gemfile.lock should reference mini_racer x86_64-linux binaries' do
    unless File.read('Gemfile.lock').include?(EXPECTED_MINI_RACER_ROWS)
      flunk <<~MSG.chomp
        Expected Gemfile.lock to include the following rows:
        #{EXPECTED_MINI_RACER_ROWS.chomp}

        We want to run a newer version of the mini_racer, but it won’t compile on CentOS 7
        without a huge set of extra packages and configuration. So we’ve built our own binaries,
        but they’re not listed on the official repository, so occasionally bundle update removes
        the special rows from Gemfile.lock and we need to add them back in.

        To fix this, run the following commands:
          bundle lock --add-platform x86_64-linux
          grep -A1 '^    mini_racer' Gemfile.lock

        Expect to see the following output from grep:
              mini_racer (0.12.0)
                libv8-node (~> 21.7.2.0)
          --
              mini_racer (0.12.0-x86_64-linux)
                libv8-node (~> 21.7.2.0)

        If they're not there already, add the last 2 lines above, immediately after the first 2.
        (See also vendor/mini_racer-x86_64-linux-ruby30/CentOS7_build_notes_ruby30.txt)
      MSG
    end
  end
end
