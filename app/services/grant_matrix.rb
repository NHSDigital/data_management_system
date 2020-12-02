# Parses the params submitted by the checkbox matrix of grants
class GrantMatrix
  def initialize(params)
    @params = params
  end

  def call
    grant_hash(grant_params.tap { |hash| clean_up!(hash) })
  end

  def grant_hash(hash)
    new_hash = {}
    hash.each do |roleable_type, roleable_type_hash|
      roleable_type_hash.each  do |roleable, role_hash|
        role_hash.each do |role, granted|
          new_hash[roleable.merge(roleable_id: role, roleable_type: roleable_type)] = granted
        end
      end
    end

    new_hash
  end

  private

  def grant_params
    # Of the form:
    # { 'RoleType: { 'A1234' => {1 => "1", 2 => "1"}, 'A12345' => {1 => "1", 2 => "" } } }
    @params.require(:grants).permit!.to_h
  end

  def clean_up!(hash)
    hash.each do |roleable_type, roleable_type_hash|
      send("clean_#{roleable_type.underscore}_params", roleable_type_hash)
      roleable_type_hash.each_value { |value| clean_roles_and_grants!(value) }
    end

    hash
  end

  def clean_system_role_params(hash)
    hash.transform_keys! { |_| {} }
  end

  def clean_team_role_params(hash)
    hash.transform_keys! { |key| { team_id: Team.find(key).id } }
  end

  def clean_project_role_params(hash)
    hash.transform_keys! { |key| { project_id: Project.find(key).id } }
  end

  def clean_roles_and_grants!(hash)
    hash.transform_values! { |value| value.present? }
  end

  def clean_dataset_role_params(hash)
    hash.transform_keys! { |key| { dataset_id: Dataset.find(key).id } }
  end
end
