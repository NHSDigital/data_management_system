module OdrDataImporter
  module ApplicationImporter
    def import_applications
      headers = @excel_file.shift.map(&:downcase)

      @excel_file.each do |application|
        attrs = headers.zip(application).to_h
        unused_columns = headers - Project.new.attributes.keys

        # Make a new project
        application = Project.new(attrs.reject { |k, _| unused_columns.include? k })

        # Set the correct attributes like a user being an instance of User
        # assigned_to
        if attrs['assigned_to'].present?
          user_assigned_to = attrs['assigned_to']&.split
          application.assigned_to = User.find_by(first_name: user_assigned_to[0],
                                                 last_name: user_assigned_to[1])
        end

        # receiptsentby
        if attrs['receiptsentby'].present?
          receipt_sent_by = attrs['receiptsentby']&.split
          application.receiptsentby = User.find_by(first_name: receipt_sent_by[0],
                                                   last_name: receipt_sent_by[1])
        end

        # project_type
        application.project_type = application_project_type

        # TODO: I think I am missing some organisations locally...
        # Organisation & team
        org_name = attrs['organisation_name']
        org = Organisation.where('name ILIKE ?', org_name.strip).first
        team_name = attrs['team_name']

        # temp make them just to get applications made...
        if org.blank?
          type = Lookups::OrganisationType.find 2

          org = Organisation.create(name: org_name, organisation_type: type)
          active_team_status = ZTeamStatus.find_by(name: 'Active')
          org.teams.find_or_create_by!(name: team_name.strip, z_team_status: active_team_status)
        end
        # temp make them just to get applications made...

        # raise "#{attrs['project_title']}: Couldn't find org: #{attrs['organisation']}" if org.blank?

        team = org.teams.where('name ILIKE ?', team_name.strip).first

        next if team.blank?
        # raise "#{attrs['project_title']}: Couldn't find team: #{attrs['team']}" if team.blank?

        application.team = team

        # article 6 & article 9 - Legal Basis
        lawful_bases = []

        lawful_bases << attrs['article6'] if attrs['article6'].present?

        if attrs['article9'].present?
          article9s = attrs['article9'].split(/(?=Art\.)/)
          article9s = article9s.map { |article| article.gsub(/Art.\d.2./, 'Art. 9.2')}

          lawful_bases << article9s
        end

        lawful_bases.each do |lawful_basis|
          lawful_base = Lookups::LawfulBasis.where('value ILIKE ?', lawful_basis)

          application.lawful_bases << lawful_base
        end if lawful_bases.present?

        # data_to_contact_others
        if attrs['data_to_contact_others'].present?
          contact_others = attrs['data_to_contact_others'].downcase

          application.data_to_contact_others = contact_others == 'no' ? false : true
        end

        # App_status
        # TODO: TBC - Waiting for mapping

        # description
        # TODO: This will be corrected in the import spreadsheet

        # level_of_identifiability
        if attrs['level_of_identifiability'].present?
          application.level_of_identifiability = Lookups::IdentifiabilityLevel.where(
            'value ILIKE ?', attrs['level_of_identifiability']).first
        end

        # data_end_use
        if attrs['data_end_use'].present?
          attrs['data_end_use'].split(';').each do |end_use|
            application.end_uses << EndUse.where('name ILIKE ?', end_use.strip)
          end
        end

        # TODO: I think this shouldnt be ID's...
          # data_asset_required
          # if attrs['data_asset_required'].present?
          #   # The spreadsheet is ID's at the minute. This should change to names...
          #   attrs['data_asset_required'].split(';').each do |dataset_id|
          #     if Dataset.find(dataset_id).blank?
          #       next
          #       # raise "#{attrs['project_title']}: No dataset found for #{dataset_id}"
          #     else
          #       pd = ProjectDataset.new(dataset: Dataset.find(dataset_id),
          #                             terms_accepted: true)
          #       application.project_datasets << pd
          #     end
          #   end
          # attrs['data_asset_required'].split(';').each do |dataset_name|
          #   if Dataset.where('name ILIKE ?', dataset_name).first.blank?
          #     raise "#{attrs['project_title']}: No dataset found for #{dataset_name}" 
          #   else
          #     pd = ProjectDataset.new(dataset: Dataset.find_by(name: dataset_name),
          #                           terms_accepted: true)
          #     application.project_datasets << pd
          #   end
          # end
        # end

        # section_251_exempt
        # TODO: ID's dont make sense.
        # Lookups::CommonLawExemption.pluck(:id, :value)
        # => [[1, "Informed Consent"], [2, "Direct Care Relationship"], [3, "S251 Regulation 2"], [4, "S251 Regulation 3"], [5, "S251 Regulation 5"], [6, "Other"]]

        # data_linkage
        # TODO: data_linkage this is a text field that the form says ‘Specify any data linkage requirements and data flows’ but the spreadsheet is boolean?

        # data_already_held_for_project
        application.data_already_held_detail = attrs['data_already_held_for_project']

        # processing_territory_id
        if attrs['processing_territory_id'].present?
          application.processing_territory = Lookups::ProcessingTerritory.where(
            'value ILIKE ?', attrs['processing_territory_id']).first
        end

        # TODO: security_assurance_id
        application.security_assurance_id =
          Lookups::SecurityAssurance.where('value ILIKE ?', attrs['security_assurance_id']).first
        # security_assurance_id doesn’t match values I have in Lookups::SecurityAssurance 
        # or the mappings in fetch_security_assurance is that correct? 
        # I cannot find IG Toolkit Level 2 anywhere actually…

        application.owner = User.where('email ILIKE ?', attrs['applicant_email']).first

        application.save! if application.valid?
      end
    end

    def application_project_type
      ProjectType.find_by(name: 'Application')
    end
  end
end
