module OdrDataImporter
  module DpiaImporter
    # TODO
    def create_dpia(application, attrs)
      ig_assessment_status = Lookups::IgAssessmentStatus.where(
        'value ILIKE ?', attrs['ig_assessment_status - new system']
      ).first

      application.dpias.create!(
        ig_toolkit_version: attrs['ig_toolkit_version - new system'],
        ig_assessment_status: ig_assessment_status,
        review_meeting_date: attrs['stage2scheduledreview'],
        dpia_decision_date: attrs['decisiondate']
      ) unless @test_mode
    end  
  end
end
