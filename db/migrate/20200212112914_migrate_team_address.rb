# Migrate team fields to address table
class MigrateTeamAddress < ActiveRecord::Migration[6.0]
  def up
    %w[New Active Closed Deleted].each do |status|
      ZTeamStatus.find_or_create_by!(name: status)
    end

    attrs = %w[location telephone]
    Team.all.each do |team|
      address_attrs = { city: team.location, telephone: team.telephone, postcode: team.postcode }
      next if address_attrs.all? { |_, v| v.blank? }

      team.addresses.build(address_attrs)
      team.save!
    end
  end

  def down
    # Do nothing
  end
end
