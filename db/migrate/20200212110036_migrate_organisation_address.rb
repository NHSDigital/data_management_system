# Migrate Organisatio address fields to new Address table
class MigrateOrganisationAddress < ActiveRecord::Migration[6.0]
  def up
    attrs = %w[add1 add2 city postcode telephone dateofaddress country_id]
    Organisation.all.each do |org|
      address_attrs = attrs.zip(org.attributes.values_at(*attrs)).to_h
      next if address_attrs.all? { |_, v| v.blank? }

      org.addresses.build(address_attrs)
      org.save!
    end
  end

  def down
    # Do nothing
  end
end
