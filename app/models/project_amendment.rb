# An `amendment` represents a formal request to change a `project` in some way, usually late in
# the lifecycle.
class ProjectAmendment < ApplicationRecord
  include HasManyReferers

  has_paper_trail

  # Quick/dirty categorization for an `amendment`
  LABELS = [
    'Data Flows',
    'Data Items',
    'Data Sources',
    'Processing Purpose',
    'Data Processor',
    'Duration',
    'Other'
  ].freeze

  belongs_to :project
  belongs_to :project_state, class_name: 'Workflow::ProjectState'

  has_one :attachment, -> { where(name: ::ProjectAttachment::Names::AMENDMENT) },
          class_name: 'ProjectAttachment',
          as:         :attachable,
          dependent:  :destroy,
          inverse_of: :attachable,
          required:   false

  with_options to: :attachment, allow_nil: true do
    delegate :attachment_contents
    delegate :attachment_file_name
    delegate :attachment_file_size
    delegate :attachment_content_type
    delegate :digest
  end

  before_validation :associate_with_project_state

  validates :requested_at, presence: true
  validates :requested_at, date: { no_future: true }
  validates :amendment_approved_date, date: { no_future: true }

  validate :ensure_valid_attachment
  validate :ensure_valid_pdf

  after_initialize :populate_reference
  after_create :increment_amendment_number

  def upload=(file)
    (attachment || build_attachment).upload = file
  end

  def populate_reference
    return if persisted?

    self.reference = project&.next_amendment_reference
  end

  def increment_amendment_number
    project.update_column(:amendment_number, project.amendment_number + 1)
  end

  private

  def associate_with_project_state
    self.project_state ||= project&.current_project_state
  end

  def ensure_valid_attachment
    return unless attachment
    return if attachment.valid?

    errors.add(:attachment, :invalid)
    errors.merge!(attachment.errors)
  end

  def ensure_valid_pdf
    return if attachment_contents.blank?

    io = StringIO.new(attachment_contents)
    PDF::Reader.new(io)
  rescue ArgumentError, PDF::Reader::MalformedPDFError
    errors.add(:attachment, :bad_pdf)
  end
end
