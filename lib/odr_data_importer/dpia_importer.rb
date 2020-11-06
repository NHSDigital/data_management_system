module OdrDataImporter
  module DpiaImporter
    # TODO
    def create_dpia(application, attrs)
      ig_assessment_status = Lookups::IgAssessmentStatus.where(
        'value ILIKE ?', attrs['ig_assessment_status_id']
      ).first

      application.dpias.create!(
        reference: attrs['dpia_ref'],
        ig_toolkit_version: attrs['ig_toolkit_version'],
        ig_assessment_status: ig_assessment_status,
        review_meeting_date: attrs['review_meeting_date'],
        dpia_decision_date: attrs['dpia_decision_date']
      ) unless @test_mode
    end  
  end
end
