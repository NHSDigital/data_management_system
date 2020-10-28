module OdrDataImporter
  # Use for importing various data supplied by ODR
  # Usage:
  # a = OdrDataImporter::Base.new('file')
  # a.build_application_managers!
  # Organisation.where("date_trunc('day', created_at) = current_date").destroy_all
  # OdrDataImporter::Base.new('EOI_data_for_import_20201023.xlsx').import_organisations_and_teams!
  # OdrDataImporter::Base.new('EOI_data_for_import_20201023.xlsx').import_users_for_eois!
  # OdrDataImporter::Base.new('EOI_data_for_import_20201023.xlsx').import_eois!
  # Project.of_type_eoi.where("date_trunc('day', projects.created_at) = current_date").map(&:application_date).compact.count
  # a = OdrDataImporter::Base.new('EOI_data_for_import_20201023.xlsx')
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
      Project.transaction do
        counter = 0
        @excel_file.each do |eoi|
          counter += 1
          eoi_attrs = header.zip(eoi).to_h
          puts "EMAIL => #{eoi_attrs['Applicant_Email']}"
          # next if eoi_attrs['Applicant_Email'].nil?
          eoi_attrs['Applicant_Email'] = '' if eoi_attrs['Applicant_Email'].nil?
          new_eoi = build_eoi(eoi_attrs.except('Data_Asset_Required'))

          # This relies on ODR actually mapping their dataset names to NCRAS
          if eoi_attrs['Data_Asset_Required'].present?
            eoi_attrs['Data_Asset_Required'].split(',').each do |dataset_name|
              raise "#{eoi_attrs['name']}: No dataset found for #{dataset_name}" if
                Dataset.odr.find_by(name: map_dataset[dataset_name] || dataset_name).nil?
              pd = ProjectDataset.new(dataset: Dataset.odr.find_by(name: map_dataset[dataset_name] || dataset_name),
                                      terms_accepted: true)
              new_eoi.project_datasets << pd
            end
          end
          puts "ABOUT TO SAVE #{counter}"
          new_eoi.save!
        rescue StandardError => e
          puts e.message
          if e.message == 'Validation failed: Project Title Name already being used by this Team'
            attempt_unique_name(new_eoi)
          else
            binding.pry
            raise
          end
        end
      end

      print "Created #{Project.count - initial_project_count} EOIs\n"
    end

    def attempt_unique_name(new_eoi)
      new_eoi.name = new_eoi.name + ' - ' + new_eoi.application_log
      new_eoi.save!
    end
      
    def build_eoi(attrs)
      eoi_attrs = attrs.reject { |k, _| eoi_fields.exclude? k }
      eoi_attrs.transform_keys! { |k| header_to_field_mapping[k] || k }
      eoi = Project.new(eoi_attrs)
      eoi.name = attrs['name']
      eoi.project_purpose = attrs['description']
      eoi.project_type = eoi_project_type
      binding.pry
      raise
      eoi.owner = User.find_by(email: attrs['Applicant_Email'].downcase)
      eoi.states << Workflow::State.find_by(id: state_mapping[attrs['Current_Status']] || attrs['Current_Status'].upcase)
      org = Organisation.find_by(name: attrs['Organisation_Name'])
      raise "#{eoi_attrs['name']}: Couldn't find org: #{attrs['Organisation_Name']}" if org.nil?

      team = org.teams.find_by(name: attrs['organisation_department'])
      raise "#{eoi_attrs['name']}: Couldn't find team: #{attrs['organisation_department']}" if team.nil?

      eoi.team = team
      if attrs['Data_End_Use'].present?
        attrs['Data_End_Use'].split(',').each do |end_use|
          if end_use == 'Other'
            eoi.end_use_other = 'Other'
          else
            eoi.end_uses << EndUse.find_by(name: end_use)
          end
        end
      end

      app_man_for_eoi = app_man(attrs['Assigned_user_id'])
      # raise "#{attrs['Assigned_user_id']} application manager not found" if app_man_for_eoi.nil?

      eoi.assigned_user = app_man_for_eoi

      cr = attrs['Closure_reason_id']
      eoi.closure_reason = Lookups::ClosureReason.find_by(value: cr) if cr.present?

      eoi
    rescue StandardError => e
      puts e.message
      puts eoi_attrs
    end

    def app_man(email)
      return if ['sean.mcphail@phe.gov.uk'].include? email

      User.find_by(email: email)
    rescue StandardError => e
      puts e.message
      puts eoi_attrs
     end

    def eoi_fields
      %w[application_log description Level_of_Identifiability Application_Date]
    end

    def eoi_project_fields
      %w[Assigned_user_id Current_Status]
    end

    def eoi_project_type
      ProjectType.find_by(name: 'EOI')
    end

    def state_mapping
      { 
        'Pending' => 'SUBMITTED',
        'Closed'  => 'REJECTED',
        'New'     => 'DRAFT'
      }
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
        'Cancer Registry' => 'Cancer registry',
        'DIDs'            => 'Linked DIDs',
        # TODO: spelt wrong on system
        'Congenital anomalies' => 'Congential anomalies',
        'Linked HES Admitted care (IP)' => 'Linked HES Admitted Care (IP)',
        ' Linked HES Admitted Care(IP)' => 'Linked HES Admitted Care (IP)',
        'Screening Programme - Breast ' => 'Screening Programme - Breast',
        'Cancer Registrys' => 'Cancer registry',
        'CPES wave 3' => 'CPES Wave 3',
        'PROMs colorectal - 2013' => 'PROMs - colorectal 2013',
        ' PROMS colorectal - 2013' => 'PROMs - colorectal 2013',
        ' PROMS colorectal 2013' => 'PROMs - colorectal 2013',
        ' PROMS pilot 2011-2012' => 'PROMs pilot 2011-2012',
        ' PROMs pilot 2011-2012' => 'PROMs pilot 2011-2012',
        # TODO: spelt wrong on system
        'Screening Programme - Fetal Anomaly' => 'Screening Programme - Fetal Anonaly',
        'PHE Screening - Bowel Screening Programme' => 'Screening Programme - Bowel',
        'PHE Screening - Newborn Hearing Screening Programme' => 'Screening Programme - Newborn Hearing'
        
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

    def header_to_field_mapping
      {
        'Level_of_Identifiability' => 'level_of_identifiability',
        'Application_Date' => 'application_date'
      }
    end
  end
end
