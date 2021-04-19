require 'test_helper'

class JobsTest < ActionDispatch::IntegrationTest
  def setup
    sign_in users(:developer)
  end

  test 'should get index' do
    visit jobs_path

    assert_equal jobs_path, current_path
  end

  test 'should get show' do
    job = delayed_jobs(:failed)

    visit jobs_path

    click_link('Details', href: job_path(job))

    assert_equal job_path(job), current_path
    assert has_link?(href: jobs_path)
    assert has_link?('Delete', href: job_path(job))
  end

  test 'should delete jobs' do
    job = delayed_jobs(:failed)

    visit jobs_path

    assert_difference -> { Delayed::Job.count }, -1 do
      accept_prompt do
        click_link('Delete', href: job_path(job))
      end

      assert_equal jobs_path, current_path
      assert has_text?('Job was successfully destroyed')
      assert has_no_text?('Cannot destroy job')
      assert has_no_selector?('tr', id: "job_#{job.id}")
    end
  end

  test 'should not delete running jobs' do
    job = delayed_jobs(:running)

    visit jobs_path

    assert_no_difference -> { Delayed::Job.count } do
      accept_prompt do
        click_link('Delete', href: job_path(job))
      end

      assert_equal jobs_path, current_path
      assert has_no_text?('Job was successfully destroyed')
      assert has_text?('Cannot destroy job')
      assert has_selector?('tr', id: "job_#{job.id}")
    end
  end

  test 'should not allow unauthorized access' do
    skip

    sign_out users(:developer)
    sign_in users(:admin_user)

    visit jobs_path

    assert_equal root_path, current_path
    assert has_text?('not authorized')
  end

  test 'should gracefully handle ActiveRecord::RecordNotFound errors' do
    job = delayed_jobs(:running)

    visit jobs_path

    assert has_link?('Details', href: job_path(job))

    # Simulate DelayedJob completing and destroying the job in the background
    assert job.destroy

    click_link('Details', href: job_path(job))

    assert has_text?('Job not found')
    assert has_no_selector?('tr', id: "job_#{job.id}")
    assert_equal jobs_path, current_path
  end
end
