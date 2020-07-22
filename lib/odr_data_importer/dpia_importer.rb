module OdrDataImporter
  module DpiaImporter
    def import_dpias
      pre_migration_count = DataPrivacyImpactAssessment.count
      dpia_headers = @excel_file.shift.map(&:downcase)

      # TODO: This should be DRY'd up witht the amendment_importer
      applications = read_excel_file(SafePath.new('db_files').join('Application data 20200713.xlsx'), 'Applications')
      # TODO: applications = read_excel_file(SafePath.new('db_files').join(ENV['application_fname']), 'Applications')

      applications_headers = applications.shift.map(&:downcase)
      required_application_data_hash = {}

      applications.each do |application|
        applications_attrs = applications_headers.zip(application).to_h

        required_application_data_hash[applications_attrs['application_log']] = {
          name: applications_attrs['name']
        }
      end

      missing_ids = []
      @excel_file.each do |dpia|
        dpia_attrs = dpia_headers.zip(dpia).to_h

        # TODO: Add handling of suffixed ids
        if required_application_data_hash[dpia_attrs['application log']]
          application_name = required_application_data_hash[dpia_attrs['application log']][:name]
        else
          missing_ids << dpia_attrs['application log']
          next
        end

        project = Project.where('name ILIKE ?', application_name).first
        ig_assessment_status = Lookups::IgAssessmentStatus.where(
          'value ILIKE ?', dpia_attrs['ig_assessment_status - new system']
        ).first

        project.dpias.create(
          ig_toolkit_version: dpia_attrs['ig_toolkit_version - new system'],
          ig_assessment_status: ig_assessment_status,
          review_meeting_date: dpia_attrs['stage2scheduledreview'],
          dpia_decision_date: dpia_attrs['decisiondate']
        )
      end

      post_migration_count = DataPrivacyImpactAssessment.count
      total_created = post_migration_count - pre_migration_count

      puts "Created #{total_created} DPIAs" if total_created >= 1
      puts "These IDs were missing: #{missing_ids.join(', ')}" if missing_ids.present?
    end
  end
end
