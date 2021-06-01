# An association extension, that allows the restriction of
# rows on a has_many through: :grant association.
module GrantedBy
  def through_grant_of(role)
    where(grants: { roleable: role })
  end
end
