# Parses the params submitted by the checkbox matrix of grants
class TeamGrantMatrix
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
  
  def clean_up!(hash)
    hash[:users].each do |user, user_hash|
      user_hash.transform_values! { |value| value.present? }
    end
    hash
  end  
end


