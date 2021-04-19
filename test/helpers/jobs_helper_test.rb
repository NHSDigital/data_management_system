require 'test_helper'

class JobsHelperTest < ActionView::TestCase
  test 'jos_status (queued)' do
    job = delayed_jobs(:queued)
    expected = <<~HTML.strip
      <span class="text-info"><span class="glyphicon glyphicon-time"></span> Queued</span>
    HTML

    assert_dom_equal expected, job_status(job)
  end

  test 'job_status (running)' do
    job = delayed_jobs(:running)
    expected = <<~HTML.strip
      <span class="text-warning"><span class="glyphicon glyphicon-retweet"></span> Running</span>
    HTML

    assert_dom_equal expected, job_status(job)
  end

  test 'job_status (failed)' do
    job = delayed_jobs(:failed)
    expected = <<~HTML.gsub("\n", '')
      <span class="text-danger">
      <span class="glyphicon glyphicon-exclamation-sign"></span> Failed
      </span>
    HTML

    assert_dom_equal expected, job_status(job)
  end
end
