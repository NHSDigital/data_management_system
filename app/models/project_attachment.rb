# ProjectAttachments are the signed ONS forms
# required to approve a Project
# The whole file upload approach needs re-working / DRYing up - it grew and grew etc
class ProjectAttachment < ApplicationRecord
  belongs_to :attachable, polymorphic: true

  # These are hard-coded all over the place, and should be dried up:
  module Names
    DATA_AGREEMENT   = 'ONS Data Agreement Form'.freeze
    DECLARATION_LIST = 'ONS Short Declaration List'.freeze
    DECLARATION_USE  = 'ONS Short Declaration of Use'.freeze
    REC_APPROVAL     = 'REC Approval Letter'.freeze
    CALDICOTT_LETTER = 'Calidicott Approval Letter'.freeze
    EXEMPTION_251    = 'Section 251 Exemption'.freeze
    SLSP             = 'SLSP'.freeze
    DATA_END_USERS   = 'Data End Users'.freeze
    DPIA             = 'DPIA'.freeze
    CONTRACT         = 'Contract'.freeze
    APPLICATION_FORM = 'Application Form'.freeze
    PROTOCOL         = 'Protocol'.freeze
    DATA_DICTIONARY  = 'Data Dictionary'.freeze
    MISC             = 'Miscellaneous'.freeze
    AMENDMENT        = 'Amendment'.freeze
  end

  scope :data_agreement, -> { where(name: Names::DATA_AGREEMENT) }
  scope :declaration_list, -> { where(name: Names::DECLARATION_LIST) }
  scope :declaration_use, -> { where(name: Names::DECLARATION_USE) }
  scope :rec_approval, -> { where(name: Names::REC_APPROVAL) }
  scope :caldicott_letter, -> { where(name: Names::CALDICOTT_LETTER) }
  scope :exemption_251, -> { where(name: Names::EXEMPTION_251) }
  scope :slsp, -> { where(name: Names::SLSP) }
  scope :data_end_users, -> { where(name: Names::DATA_END_USERS) }
  scope :uploads, -> { where.not(name: Names::DATA_END_USERS) }
  scope :dpia, -> { where(name: Names::DPIA) }
  scope :contract, -> { where(name: Names::CONTRACT) }
  scope :application_forms, -> { where(name: Names::APPLICATION_FORM) }

  # Allow for auditing/version tracking of ProjectAttachment
  has_paper_trail

  attr_accessor :end_users_updated
  attr_accessor :end_users_added

  content_types = %w[text/plain image/jpg image/jpeg image/png image/gif application/doc
                     application/docx application/pdf text/csv application/vnd.ms-excel
                     application/vnd.openxmlformats-officedocument.wordprocessingml.document
                     application/vnd.openxmlformats-officedocument.spreadsheetml.sheet]

  CSV_CONTENT = %w[application/vnd.ms-excel text/csv].freeze

  before_validation { self[:digest] = digest unless self[:digest] }

  validates :attachment_content_type,
            inclusion: { in: content_types, message: 'Not an allowed file type!' }

  validates :attachment_file_size,
              numericality: { less_than_or_equal_to: 5.megabytes, message: 'should be less than 5MB' }

  validates :digest, presence: true, uniqueness: { scope: :attachable }
  validate  :data_end_users_csv

  delegate :name, to: :project, prefix: true # project_name

  class << self
    def relevant_types_for(project)
      if project.project?
        [
          Names::DATA_AGREEMENT,
          Names::REC_APPROVAL,
          Names::CALDICOTT_LETTER,
          Names::EXEMPTION_251,
          Names::SLSP
        ]
      elsif project.application?
        [
          Names::APPLICATION_FORM,
          Names::DATA_AGREEMENT,
          Names::REC_APPROVAL,
          Names::CALDICOTT_LETTER,
          Names::EXEMPTION_251,
          Names::SLSP,
          Names::PROTOCOL,
          Names::DATA_DICTIONARY,
          Names::MISC
        ]
      else
        []
      end
    end
  end

  def contents=(value)
    super(value.to_s.length.zero? ? nil : ActiveSupport::Gzip.compress(value))
    self.attachment_file_size = value.try(:bytesize)
  end

  def contents
    ActiveSupport::Gzip.decompress(super)
  rescue
    super
  end

  def digest
    super || (attachment_contents ? Digest::MD5.hexdigest(attachment_contents) : nil)
  end

  def upload=(file_upload)
    self.attachment_contents     = file_upload.read
    self.attachment_file_name    = file_upload.original_filename
    self.attachment_content_type = file_upload.content_type
    self.attachment_file_size    = file_upload.read.try(:bytesize)
    self.digest                  = digest
  end

  def valid_content_type
    return if name == 'Data End Users'
    errors.add('Not an allowed file type!') unless content_types.include? attachment_content_type
  end

  def data_end_users_csv
    return unless name == 'Data End Users'
    errors.add(:contents, 'not csv') unless CSV_CONTENT.include? attachment_content_type
  end

  def import_end_users
    return unless name == 'Data End Users'
    self.end_users_updated = 0
    self.end_users_added = 0
    CSV.parse(attachment_contents, headers: true).each do |row|
      begin
        attrs = convert_ts_cs_accepted(row.to_h.merge(project_id: project.id))
        next unless attrs.values.all?(&:present?)
        already_exists = ProjectDataEndUser.find_by(project_id: project.id, email: attrs['email'])
        if already_exists && details_different?(already_exists, attrs)
          already_exists.update(attrs)
          self.end_users_updated += 1
        end
        next if already_exists
        ProjectDataEndUser.create!(attrs)
        self.end_users_added += 1
      rescue e
        errors.add(:contents, 'bad format')
      end
    end
  end

  def project
    attachable.is_a?(Project) ? attachable : attachable&.project
  end

  private

  def details_different?(existing, attrs)
    present = existing.attributes.values_at('first_name', 'last_name', 'email', 'ts_cs_accepted')
    present != attrs.except(:project_id).map { |k, v| k == 'ts_cs_accepted' ? v == 1 : v }
  end

  def convert_ts_cs_accepted(attrs)
    attrs['ts_cs_accepted'] = attrs['ts_cs_accepted'].downcase == 'yes' ? 1 : 0
    attrs
  end
end
