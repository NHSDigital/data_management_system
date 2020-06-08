# Identifies Teams that can be
# edited by the current_user
module TeamEditable
  def editable
    merge(Membership.senior)
  end
end
