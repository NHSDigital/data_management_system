module OdrDataImporter
  # Use for importing various data supplied by ODR
  # Usage:
  # a = OdrDataImporter::Base.new('file')
  # a.build_application_managers!
  # a = OdrDataImporter::Base.new('file')
  # a.import_organisations_and_teams!
  # b = OdrDataImporter::Base.new('file')
  # b.import_users_for_eois!
  # c = OdrDataImporter::Base.new('file')
  # c.import_eois!
  class Base
    require 'ndr_import/helpers/file/excel'
    include NdrImport::Helpers::File::Excel
    include OdrDataImporter::OrganisationsAndTeams
    include OdrDataImporter::Users
    include OdrDataImporter::OrganisationUpdater
    include OdrDataImporter::OrganisationImporter
    include OdrDataImporter::TeamsImporter
    include OdrDataImporter::UsersImporter
    include OdrDataImporter::ApplicationImporter
    include OdrDataImporter::AmendmentImporter
    include OdrDataImporter::DpiaImporter
    include OdrDataImporter::ContractImporter
    include OdrDataImporter::ReleaseImporter
    include OdrDataImporter::ApplicationMatcher
    include OdrDataImporter::ApplicationSubClassImporter

    attr_accessor :excel_file
    def initialize(fname, worksheet = nil, test_mode = 'true')
      @fname      = fname
      @excel_file = read_excel_file(SafePath.new('tmp').join(fname), worksheet)
      @test_mode  = ActiveModel::Type::Boolean.new.cast(test_mode)
    end

    def import_eois!
      initial_project_count = Project.count
      header = @excel_file.shift
      @excel_file.each do |eoi|
        eoi_attrs = header.zip(eoi).to_h
        new_eoi = build_eoi(eoi_attrs.except('Data_Asset_Required'))
        # This relies on ODR actually mapping their dataset names to NCRAS
        if eoi_attrs['Data_Asset_Required'].present?
          eoi_attrs['Data_Asset_Required'].split(';').each do |dataset_name|
            raise "#{eoi_attrs['name']}: No dataset found for #{dataset_name}" if
              Dataset.odr.find_by(name: dataset_name).nil?
            pd = ProjectDataset.new(dataset: Dataset.odr.find_by(name: dataset_name),
                                    terms_accepted: true)
            new_eoi.project_datasets << pd
          end
        end
        new_eoi.save!
      end

      print "Created #{Project.count - initial_project_count} EOIs\n"
    end

    def build_eoi(attrs)
      eoi = Project.new(attrs.reject { |k, _| eoi_fields.exclude? k })
      eoi.name = attrs['name']
      eoi.project_type = eoi_project_type
      eoi.owner = User.find_by(email: attrs['Applicant_Email'].downcase)
      eoi.states << Workflow::State.find_by(id: state_mapping[attrs['Current_Status']])
      org = Organisation.find_by(name: attrs['Organisation_Name'])
      raise "#{attrs['name']}: Couldn't find org: #{attrs['Organisation_Name']}" if org.nil?

      team = org.teams.find_by(name: attrs['organisation_department'])
      raise "#{attrs['name']}: Couldn't find team: #{attrs['organisation_department']}" if team.nil?

      eoi.team = team
      if attrs['Data_End_Use'].present?
        attrs['Data_End_Use'].split(';').each do |end_use|
          eoi.end_uses << EndUse.find_by(name: end_use)
        end
      end

      app_man_for_eoi = app_man(attrs['Assigned_user_id'])
      raise "#{attrs['Assigned_user_id']} application manager not found" if app_man_for_eoi.nil?

      eoi.assigned_user = app_man_for_eoi

      cr = attrs['Closure_reason_id']
      eoi.closure_reason = Lookups::ClosureReason.find_by(value: cr) if cr.present?

      eoi
    end

    # TODO: what are the responses in the file?

    def app_man(name_string)
      email = name_string.split.join('.').downcase + '@phe.gov.uk'
      User.find_by(email: email)
    end

    def eoi_fields
      %w[application_log description Level_of_Identifiability]
    end

    def eoi_project_fields
      %w[Assigned_user_id Current_Status]
    end

    def eoi_project_type
      ProjectType.find_by(name: 'EOI')
    end

    def state_mapping
      { 'Pending' => 'SUBMITTED' }
    end

    private

    # NCRAS field name, Node name
    # 'Data item' => 'description',
    # 'Field name' => 'name',
    # 'Description of field content' => 'description_detail',
    # 'Derived' => 'Derived',
    # "governance" => governance,
    # 'parent_node' => 'parent_node'

    def ignored_fields
      %w[governance parent_node]
    end

    def node_fields
      %w[description name description_detail derived governance parent_node]
    end

    def occurrences
      { min_occurs: 0, max_occurs: 1 }
    end

    def map_dataset
      {
        'Cancer registry' => 'Cancer Registry'
      }
    end

    def log_to_process_count(total)
      print "***TEST_MODE***\n" if @test_mode
      print "#{'*' * 10}\n"
      print "Number of rows in tab to process => #{total}\n"
    end

    def errors_to_file(errors, filename)
      filename = "#{Time.current.strftime('%Y%m%d')}_#{filename}.csv"
      file = Rails.root.join('tmp').join(filename)
      CSV.open(file, 'wb') do |csv_out|
        errors.each { |error| csv_out << Array.wrap(error) }
      end
      print "tmp/#{filename} output file created\n"
    end
  end
end
