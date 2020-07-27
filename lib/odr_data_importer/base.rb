module OdrDataImporter
  # Use for importing various data supplied by ODR
  # Usage:
  # a = OdrDataImporter::Base.new('20191115 List of application managers.xlsx')
  # a.build_application_managers!
  # a = OdrDataImporter::Base.new('20200130_SampleEOIData_sample_kl.xlsx', 'Address list')
  # a.import_organisations_and_teams!
  # b = OdrDataImporter::Base.new('20200130_SampleEOIData_sample_kl.xlsx', 'SeniorUsers')
  # b.import_users_for_eois!
  # c = OdrDataImporter::Base.new('20200130_SampleEOIData_sample_kl.xlsx', 'EOI_Detail')
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
        new_eoi = build_eoi(eoi_attrs.except('data_asset_required'))
        # This relies on ODR actually mapping their dataset names to NCRAS
        if eoi_attrs['data_asset_required'].present?
          eoi_attrs['data_asset_required'].split(';').each do |dataset_name|
            raise "#{eoi_attrs['project_title']}: No dataset found for #{dataset_name}" if
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
      eoi.name = attrs['project_title']
      eoi.project_type = eoi_project_type
      eoi.owner = User.find_by(email: attrs['senior_user_email'].downcase)
      eoi.states << Workflow::State.find_by(id: state_mapping[attrs['EOI_status']])
      org = Organisation.find_by(name: attrs['organisation'])
      raise "#{attrs['project_title']}: Couldn't find org: #{attrs['organisation']}" if org.nil?

      team = org.teams.find_by(name: attrs['team'])
      raise "#{attrs['project_title']}: Couldn't find team: #{attrs['team']}" if team.nil?

      eoi.team = team
      if attrs['data_end_use'].present?
        attrs['data_end_use'].split(';').each do |end_use|
          eoi.end_uses << EndUse.find_by(name: end_use)
        end
      end

      app_man_for_eoi = app_man(attrs['application_manager'])
      raise "#{attrs['application_manager']} application manager not found" if app_man_for_eoi.nil?

      eoi.assigned_user = app_man_for_eoi
      eoi
    end

    # TODO: what are the responses in the file?

    def app_man(name_string)
      email = name_string.split.join('.').downcase + '@phe.gov.uk'
      User.find_by(email: email)
    end

    def eoi_fields
      %w[application_log project_purpose level_of_identifiability]
    end

    def eoi_project_fields
      %w[application_manager EOI_status]
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
    end
  end
end
