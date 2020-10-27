module OdrDataImporter
  module OrganisationsAndTeams
    def import_organisations_and_teams!
      initial_org_count = Organisation.count
      initial_team_count = Team.count
      @header = @excel_file.shift
      build

      print "Created #{Organisation.count - initial_org_count} Organisations\n"
      print "Created #{Team.count - initial_team_count} Teams\n"
    end

    def build
      build_organisations
      build_teams
    end

    def build_organisations
      @excel_file.each do |row|
        attrs = @header.zip(row).to_h
        attrs.delete_if { |k, _| k.nil? }
        Organisation.transaction do
          create_organisation(attrs)
        end
      end
    end

    def build_teams
      @excel_file.each do |row|
        attrs = @header.zip(row).to_h
        attrs.delete_if { |k, _| k.nil? }
        Team.transaction do
          create_team(attrs)
        end
      end
    end

    def create_organisation(attrs)
      return if Organisation.find_by(name: attrs['Organisation_Name']).present?

      country_raw = attrs.delete('Country_id').upcase
      country = Lookups::Country.find_by(value: country_raw)
      org_type_raw = attrs.delete('Org_Type_id')
      org_type_raw = org_type_name_mapping[org_type_raw] || org_type_raw
      org_type = Lookups::OrganisationType.find_by(value: org_type_raw)
      raise "no org type! #{org_type_raw}" if org_type.nil?

      org_attrs = { name: attrs.delete('Organisation_Name') }
      org_attrs[:organisation_type] = org_type
      org_attrs[:organisation_type_other] = 'Unknown' if org_type_raw == 'Other'

      # TODO: Can't build addresses for now. multiples - build at team level instead 
      # address = attrs.transform_keys! { |key| org_mapping.invert[key] }
      # address[:country] = country
      Organisation.create!(org_attrs)
      # organisation.addresses.build(address) if
      #   ActiveRecord::Base.connection.table_exists?(:addresses)
    end

    def create_team(attrs)
      org_name = attrs.delete('Organisation_Name')
      org_type_raw = attrs.delete('Org_Type_id')

      team_attrs = {}
      team_attrs[:name] = attrs.delete('organisation_department')
      team_attrs[:location] = attrs.delete('Location')
      # team_attrs[:postcode] = attrs.delete('Post code')
      # team_attrs[:telephone] = attrs.delete('Telephone')
      team_attrs[:organisation_id] = Organisation.find_by(name: org_name).id

      raise "#{org_name} for #{team_attrs[:name]} not found" if team_attrs[:organisation_id].nil?
      raise 'No Name' if team_attrs[:name].nil?
      team_attrs[:z_team_status] = ZTeamStatus.find_by(name: 'Active')
      team = Team.where(team_attrs).first_or_initialize

      country_raw = attrs.delete('Country').upcase
      country = Lookups::Country.find_by(value: country_raw)
      address_attrs = attrs.select { |k,_| org_mapping.values.include? k }
      address = address_attrs.transform_keys! { |key| org_mapping.invert[key] }
      address[:country] = country
      unless address.values.all?(&:blank?)
        team.addresses.build(address) if ActiveRecord::Base.connection.table_exists?(:addresses)
      end
      
      # extra guard if details differ i.e ODR already exists
      return if Organisation.find_by(name: org_name).teams.pluck(:name).include? team_attrs[:name]

      team.save!
    end

    # sigh
    def org_type_name_mapping
      {
        'CQC Registered Health or/and Social Care provider' =>
          'CQC Registered Health and/or Social Care Provider',
        'Government Agency (Outside of Health and Adult Social Care)' =>
          'Government Agency (outside of Health and Adult Social Care)',
        'Government Agency (Health and Adult Social Care)' =>
          'Government Agency (Health and Social Care)',
        'CQC Registered Health or/and Social Care Provider' =>
          'CQC Registered Health and/or Social Care Provider',
        'commercial' => 'Commercial',
        'CQC Registered Health and/or Social Care provider' =>
          'CQC Registered Health and/or Social Care Provider'
      }
    end

    def org_mapping
      {
        # name: 'Organisation_Name',
        add1: 'add1',
        add2: 'add2',
        city: 'City',
        postcode: 'Postcode',
        telephone: 'Telephone'
      }
    end
  end
end
