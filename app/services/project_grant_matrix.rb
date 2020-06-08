# Parses the params submitted by the checkbox matrix of grants
class ProjectGrantMatrix
  def initialize(params)
    @params = params
  end

  def call
    grant_params.tap { |hash| clean_up!(hash) }
  end

  private

  def grant_params
    @params.require(:grants).permit!.to_h
  end

  # { project_id => 1,
  #   users => { user_id1 => { role_id1 => granted }, user_id2 => { role_id1 => granted } } }
  def clean_up!(hash)
    # hash[:users].transform_keys! { |key| { user_id: User.find(key).id } }
    hash[:users].each do |user, user_hash|
      # user_hash.transform_keys! { |key| { role_id: ProjectRole.find(key).id } }
      user_hash.transform_values! { |value| value.present? }
    end
    hash
  end  
end
