class DataPrivacyImpactAssessment < ApplicationRecord
  include BelongsToReferent

  has_paper_trail

  belongs_to :project
  belongs_to :project_state,        class_name: 'Workflow::ProjectState'
  belongs_to :ig_assessment_status, class_name: 'Lookups::IgAssessmentStatus', optional: true

  has_one :attachment, -> {
    where(name: ::ProjectAttachment::Names::DPIA)
  }, class_name: 'ProjectAttachment', as: :attachable, dependent: :destroy, inverse_of: :attachable

  with_options to: :attachment, allow_nil: true do
    delegate :attachment_contents
    delegate :attachment_file_name
    delegate :attachment_file_size
    delegate :attachment_content_type
    delegate :digest
  end

  delegate :value, to: :ig_assessment_status, allow_nil: true, prefix: true

  before_validation :associate_with_project_state

  validates :ig_score, inclusion: { in: 0..100, allow_blank: true }
  validates :ig_score, numericality: { only_integer: true, allow_blank: true }

  def upload=(file)
    (attachment || build_attachment).upload = file
  end

  private

  def associate_with_project_state
    self.project_state ||= project&.current_project_state
  end
end
