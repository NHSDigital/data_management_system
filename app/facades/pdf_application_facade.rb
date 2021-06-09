# Facade come form object for handling `Project`s in the context of an ODR data application.
class PdfApplicationFacade
  include ActiveModel::Model
  include ActiveModel::Attributes
  extend  ActiveModel::Callbacks

  attr_reader :project

  delegate :persisted?, :new_record?, to: :project

  delegate_missing_to :project

  define_model_callbacks :validate, :save

  after_validate -> { errors.merge!(project.errors) }

  before_save :assign_project_end_date
  before_save -> { copy_organisation_details(:sponsor) }
  before_save -> { copy_organisation_details(:funder) }

  attribute :form_version

  attribute :applicant_title
  attribute :applicant_first_name
  attribute :applicant_surname
  attribute :applicant_job_title
  attribute :applicant_email
  attribute :applicant_telephone

  # Let's make sure there are no unexpected changes to the (grand)parent resource as a result of
  # delegated/magic methods...
  # TODO: Who will be responsible for maintaining accurate (external) organisation data?
  attribute :organisation_name

  attribute :sponsor_same_as_applicant, :boolean, default: false
  attribute :funder_same_as_applicant,  :boolean, default: false

  attribute :level_of_identifiability
  attribute :s251_exemption

  attribute :processing_territory
  attribute :processing_territory_outsourced

  attribute :security_assurance_applicant
  attribute :security_assurance_outsourced

  alias_attribute :org_department,              :organisation_department
  alias_attribute :org_add1,                    :organisation_add1
  alias_attribute :org_add2,                    :organisation_add2
  alias_attribute :org_add_city,                :organisation_city
  alias_attribute :org_postcode,                :organisation_postcode
  alias_attribute :org_country,                 :organisation_country
  alias_attribute :project_title,               :name
  alias_attribute :project_purpose,             :description
  alias_attribute :sponsor_add_city,            :sponsor_city
  alias_attribute :funder_add_city,             :funder_city
  alias_attribute :sponsor_country,             :sponsor_country_id
  alias_attribute :funder_country,              :funder_country_id
  alias_attribute :data_processor_country,      :data_processor_country_id
  alias_attribute :test_drr_how_data_used,      :how_data_will_be_used
  alias_attribute :data_end_use_other_text,     :end_use_other
  alias_attribute :project_start_date,          :start_data_date
  alias_attribute :data_linkage_required,       :data_linkage
  alias_attribute :patient_contact_details,     :data_to_contact_others_desc
  alias_attribute :caldicott_name,              :acg_who
  alias_attribute :cag_reference,               :cag_ref
  alias_attribute :cag_date_renewal,            :date_of_renewal
  alias_attribute :data_already_held,           :data_already_held_for_project
  alias_attribute :patient_contact,             :data_to_contact_others
  alias_attribute :additional_information,      :additional_info
  alias_attribute :dpareg_end_date,             :dpa_registration_end_date
  alias_attribute :dpareg_end_date_outsourced,  :dpa_registration_end_date_outsourced
  alias_attribute :program_support,             :programme_support_id
  alias_attribute :program_support_detail,      :programme_support_detail
  alias_attribute :program_approval_date,       :programme_approval_date
  alias_attribute :data_sharing_contract_ref,   :scrn_id
  alias_attribute :test_drr_proj_sum,           :description
  alias_attribute :test_drr_why_data_req,       :why_data_required
  alias_attribute :test_drr_public_benefit,     :public_benefit
  alias_attribute :rec_reference,               :ethics_approval_nrec_ref
  alias_attribute :rec_name,                    :ethics_approval_nrec_name
  alias_attribute :informed_consent_attach,     :informed_patient_consent

  class << self
    def perform_metaprogamming
      metaprogramme_boolean_attributes
      metaprogramme_end_uses
      metaprogramme_lawful_bases
    end

    private

    def metaprogramme_boolean_attributes
      acroform_boolean_attributes = %i[
        sponsor_same_as_applicant
        funder_same_as_applicant
        data_already_held_for_project
        data_to_contact_others
        onwardly_share
        informed_patient_consent
      ]

      acroform_boolean_attributes.each do |name|
        define_method("#{name}=") do |value|
          super(cast_acroform_boolean(value))
        end
      end
    end

    def metaprogramme_end_uses
      EndUse.find_each do |end_use|
        name = end_use.name.parameterize(separator: '_')

        attribute name, :boolean, default: false

        define_method("#{name}=") do |value|
          value = cast_acroform_boolean(value)
          project.end_uses << end_use if value
          super(value)
        end
      end
    end

    # PDF attributes arrive as e.g. `6a`, `9b` (previous form versions have also
    # included the `article_` prefix, but that seems to have since been lost).
    def metaprogramme_lawful_bases
      Lookups::LawfulBasis.find_each do |lawful_basis|
        name = "article_#{lawful_basis.id.chars.values_at(0, -1).join}"

        attribute name, :boolean, default: false

        define_method("#{name}=") do |value|
          value = cast_acroform_boolean(value)
          project.lawful_bases << lawful_basis if value
          super(value)
        end
      end
    end
  end

  perform_metaprogamming

  def initialize(project, attrs = {})
    super(attrs)
    @project = project
    @project.pdf_import = true
    # Be clear about usage/limitations. Right now this class is only intended as a
    # shim/helper for creating new projects from PDF application forms...
    raise 'Not for use with persisted projects!' if persisted?

    yield(self) if block_given?
  end

  def valid?
    super && project.valid?
  end

  def save
    run_callbacks :save do
      project.transaction do
        user = create_or_update_applicant!
        project.build_owner_grant(user: user)
        project.save!
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    errors.merge!(e.record.errors)
    false
  end

  def level_of_identifiability=(value)
    classification = fetch_classification(value)
    project.classifications.replace(Array.wrap(classification))
    project.level_of_identifiability = fetch_level_of_identifiability(value)
  end

  def s251_exemption=(value)
    project.s251_exemption = fetch_s251_exemption(value)
    super(value)
  end

  def programme_support_id=(value)
    # Mapped to account for various versions of YES and NO provided by different pdf readers
    value = fetch_programme_support_id(value)
    project.programme_support_id = Lookups::ProgrammeSupport.find_by(value: value)&.id
  end

  def security_assurance_applicant=(value)
    project.security_assurance = fetch_security_assurance(value)
    super(value)
  end

  def security_assurance_outsourced=(value)
    project.security_assurance_outsourced = fetch_security_assurance(value)
    super(value)
  end

  def processing_territory=(value)
    project.processing_territory = fetch_processing_territory(value)
    super(value)
  end

  def processing_territory_outsourced=(value)
    project.processing_territory_outsourced = fetch_processing_territory(value)
    super(value)
  end

  private

  # Not sure if it's a quirk of all Acroforms, or just the ODR one(s), but boolean values are
  # being submitted as:
  # check boxes -> `:Yes` or `:Off`
  # selects     -> `Y` or `N`
  def cast_acroform_boolean(value)
    return true  if value.to_s.in? %w[Yes Y]
    return false if value.to_s.in? %w[Off N No]

    value
  end

  def fetch_classification(name)
    map = {
      'PersonallyIdentifiable' => 'identifiable',
      'DePersonalised'         => 'potentially identifiable',
      'Anonymised'             => 'Anonymised'
    }

    Classification.find_by(name: map[name.to_s])
  end

  def fetch_s251_exemption(value)
    value = value.to_s
    map   = {
      'Regulation 2' => 'S251 Regulation 2',
      'Regulation 3' => 'S251 Regulation 3',
      'Regulation 5' => 'S251 Regulation 5'
    }

    Lookups::CommonLawExemption.find_by(value: map.fetch(value, value))
  end

  # TODO: This is not currently an _id column on project
  def fetch_level_of_identifiability(value)
    map = {
      'PersonallyIdentifiable' => 'Personally Identifiable',
      'DePersonalised' => 'De-personalised',
      'Anonymised' => 'Anonymous'
    }

    map[value.to_s]
  end

  # Mapped to account for various versions of YES and NO provided by different pdf readers
  def fetch_programme_support_id(value)
    map = {
      'Y' => 'Yes',
      'N' => 'No',
      'Off' => 'No'
    }

    map[value].presence || value
  end

  def fetch_security_assurance(value)
    map = {
      'IGToolkitApplicant'  => 'Data Security and Protection Toolkit',
      'ISO27001Applicant'   => 'ISO 27001',
      'SLSPApplicant'       => 'Project specific System Level Security Policy',
      'IGToolkitOutsourced' => 'Data Security and Protection Toolkit',
      'ISO27001Outsourced'  => 'ISO 27001',
      'SLSPOutsourced'      => 'Project specific System Level Security Policy'
    }

    Lookups::SecurityAssurance.find_by(value: map[value.to_s])
  end

  def fetch_processing_territory(value)
    Lookups::ProcessingTerritory.find_by(value: value)
  end

  # TODO: This doesn't feel like the right thing to do...
  def create_or_update_applicant!
    User.find_or_initialize_by(email: applicant_email&.strip&.downcase).tap do |user|
      user.first_name = applicant_first_name
      user.last_name  = applicant_surname
      user.job_title  = applicant_job_title
      user.telephone  = applicant_telephone

      user.grants.find_or_initialize_by(roleable: TeamRole.fetch(:mbis_applicant), team: team)

      user.save!
    end
  end

  def assign_project_end_date
    return unless start_data_date && duration

    project.end_data_date = start_data_date + duration.months
  end

  def copy_organisation_details(target)
    return unless send("#{target}_same_as_applicant")

    project.assign_attributes(
      "#{target}_name":       organisation_name,
      "#{target}_add1":       organisation_add1,
      "#{target}_add2":       organisation_add2,
      "#{target}_city":       organisation_city,
      "#{target}_postcode":   organisation_postcode,
      # some pdf readers send through value instead of id
      "#{target}_country_id": Lookups::Country.find_by(value: organisation_country.upcase)&.id ||
                              organisation_country
    )
  end
end
