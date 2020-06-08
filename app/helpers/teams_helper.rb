# helper methods for teams
module TeamsHelper
  def available_users_for_team
    @membership.team.active_users_who_are_not_team_members
  end

  def edit_team_grants_button
    bootstrap_icon_tag('edit') + ' Edit team grants'
  end
end
