# An association extension, that allows the restriction of
# rows on a has_many through: :grant association.
module GrantedBy
  def through_grant_of(role, roleable_type)
    where(grants: { roleable_id: role.map(&:id), roleable_type: roleable_type })
  end
end
