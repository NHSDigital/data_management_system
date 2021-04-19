# View helper methods relating to jobs.
module JobsHelper
  STATES = {
    failed:  { icon: 'exclamation-sign', colour: 'text-danger' },
    running: { icon: 'retweet', colour: 'text-warning' },
    queued:  { icon: 'time', colour: 'text-info' }
  }.freeze

  def job_status(job)
    key =
      if job.failed_at?
        :failed
      elsif job.locked_at?
        :running
      else
        :queued
      end

    state = STATES[key]

    tag.span(class: state[:colour]) do
      safe_join([bootstrap_icon_tag(state[:icon]), key.to_s.titleize], ' ')
    end
  end
end
