class Contract < ApplicationRecord
  include BelongsToReferent

  has_paper_trail

  belongs_to :project
  belongs_to :project_state, class_name: 'Workflow::ProjectState'

  has_one :attachment, -> {
    where(name: ::ProjectAttachment::Names::CONTRACT)
  }, class_name: 'ProjectAttachment', as: :attachable, dependent: :destroy, inverse_of: :attachable

  with_options to: :attachment, allow_nil: true do
    delegate :attachment_contents
    delegate :attachment_file_name
    delegate :attachment_file_size
    delegate :attachment_content_type
    delegate :digest
  end

  before_validation :associate_with_project_state
  after_save :apply_auto_transition

  def upload=(file)
    (attachment || build_attachment).upload = file
  end

  private

  def associate_with_project_state
    self.project_state ||= project&.current_project_state
  end

  def apply_auto_transition
    return unless project_state.state_id == 'DATA_RELEASED'
    return unless destruction_form_received_date

    project.transition_to!(Workflow::State.find_by(id: 'DATA_DESTROYED'))
  end
end
