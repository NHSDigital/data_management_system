class Array
  def to_csv()
    keys = self.flat_map(&:keys).uniq
    CSV.generate do |csv|
      csv << keys
      self.each do |hash|
        csv << hash.values_at(*keys).map{|a| a.kind_of?(Array) ? a.join(' : ') : a}
      end
    end
  end
end

# Manages access to reports.
# TODO: Index action/view of all reports
class ReportsController < ApplicationController
  load_and_authorize_resource only: :show # Will load correct report class, not an instance!

  def show
    @report = @report.new(user_context: current_user)

    # TODO: Support alternative formats
    respond_to do |format|
      format.any do
        headers['Cache-Control']       = 'no-cache'
        headers['Content-Type']        = 'text/csv'
        headers['Content-Disposition'] = %(attachment; filename="#{@report.filename}.csv")
        headers.delete('Content-Length')

        response.status    = 200
        self.response_body = @report.to_csv_enum
      end
    end
  end

  def report1
    @projects = []
    Project.of_type_project.order('team_id, name').find_each do |project|
      @projects << {
        team: project.team.name,
        division: project.team&.division&.name,
        head_of_profession: project.team&.division&.head_of_profession,
        delegate_approver: project.team.delegate_users.collect(&:full_name),
        title: project.name,
        summary: project.description,
        status: project.current_state.id,
        start_date: project.start_data_date,
        end_date: project.end_data_date,
        frequency: (project.frequency == 'Other') ? project.frequency_other : project.frequency,
        senior_member: project.owner_full_name,
        members: project.users.collect(&:full_name),
        data_users: project.project_data_end_users.collect(&:email),
        end_uses: all_end_uses(project),
        # TODO: prettify me. although apparently these reports have not been requested for a while
        # 2019/11/08
        dataset: project.datasets.collect(&:name),
        data_items: project.data_items.collect(&:name)
      }
    end

    respond_to do |format|
      format.html
      format.csv { send_data @projects.to_csv }
      # format.xlx
    end
  end

  # TODO: This report is unused and should be removed.
  def report2
    @rows = []
    Team.find_each do |team|
      team.projects.of_type_project.find_each do |project|
        project.comments.each do |comment|
          @rows << {
            team_name: team.name,
            project_name: project.name,
            type: comment.tags.join(', '),
            comment: comment.body,
            item: '',
            user: comment.user_full_name
          }
        end
      end
    end
    respond_to do |format|
      format.html
      format.csv { send_data @rows.to_csv }
      # format.xls
    end
  end

  private

  # Add/Show other end use if present
  def all_end_uses(p)
    project_end_uses = p.end_uses.collect(&:name)
    p.end_use_other.nil? ? project_end_uses : (project_end_uses.push p.end_use_other)
  end
end
