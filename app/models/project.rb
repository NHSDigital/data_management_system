# Project associations and validations
class Project < ApplicationRecord
  include Workflow::Model
  include Commentable
  include Searchable
  include HasManyReferers

  has_many :project_attachments, as: :attachable, dependent: :destroy
  has_many :project_nodes, dependent: :destroy
  has_many :nodes, through: :project_nodes
  has_many :data_items, through: :project_nodes, class_name: 'Nodes::DataItem', source: :node,
                        foreign_key: 'node_id'

  has_many :project_data_end_users, dependent: :destroy
  has_many :project_outputs, dependent: :destroy
  has_many :outputs, through: :project_outputs
  has_many :project_end_uses, dependent: :destroy
  has_many :end_uses, through: :project_end_uses
  has_many :project_classifications, dependent: :destroy
  has_many :classifications, through: :project_classifications
  has_many :project_data_passwords, dependent: :destroy
  has_many :grants, foreign_key: :project_id, dependent: :destroy
  has_many :users, -> { extending(GrantedBy).distinct }, through: :grants
  has_many :project_amendments, dependent: :destroy
  has_many :communications, dependent: :destroy

  # The following associations are somewhat deprecated (and slightly confusing) now.
  # These resources should have a polymorphic parent (either a project or an amendment;
  # see `BelongsToReferent` and `HasManyReferers`).
  # That said, these associations (and their inverse counterparts) are kind of useful as a means
  # of accessing _all_ the relevant resources within the scope of a project, irrespective of the
  # true parent resource.
  with_options dependent: :destroy do
    has_many :global_dpias,     class_name: 'DataPrivacyImpactAssessment'
    has_many :global_contracts, class_name: 'Contract'
    has_many :global_releases,  class_name: 'Release'
  end

  has_many :project_lawful_bases, dependent: :destroy
  has_many :lawful_bases, through: :project_lawful_bases

  has_many :notifications, dependent: :destroy

  has_one :cas_application_fields, dependent: :destroy
  accepts_nested_attributes_for :cas_application_fields, allow_destroy: true

  belongs_to :project_type

  # roleable doesn't work here?
  has_one :owner_grant, lambda {
    where grants: { roleable_type: 'ProjectRole', roleable_id: ProjectRole.fetch(:owner).id }
  }, class_name: 'Grant'

  has_one :owner, through: :owner_grant, class_name: 'User', source: :user

  has_many :project_datasets, dependent: :destroy, inverse_of: :project
  has_many :datasets, through: :project_datasets
  validates_associated :project_datasets
  # validates_associated failing with non persisted children?
  # https://github.com/rails/rails/pull/32796
  has_many :project_dataset_levels, -> { order(:project_dataset_id, :access_level_id) },
           through: :project_datasets

  belongs_to :s251_exemption, class_name: 'Lookups::CommonLawExemption', optional: true

  belongs_to :programme_support, class_name: 'Lookups::ProgrammeSupport', optional: true

  # FIXME: These associations probably live somewhere else realistically...
  with_options class_name: 'Lookups::SecurityAssurance', optional: true do
    belongs_to :security_assurance
    belongs_to :security_assurance_outsourced
  end

  # FIXME: These associations probably live somewhere else realistically...
  with_options class_name: 'Lookups::ProcessingTerritory', optional: true do
    belongs_to :processing_territory
    belongs_to :processing_territory_outsourced
  end

  belongs_to :team, optional: true
  belongs_to :closure_reason, class_name: 'Lookups::ClosureReason', optional: true

  belongs_to :parent,   class_name: 'Project', foreign_key: :clone_of, optional: true
  has_many   :children, class_name: 'Project', foreign_key: :clone_of

  # The `assigned_user` will generally be an ODR representative responsible for the project
  belongs_to :assigned_user, class_name: 'User', inverse_of: :assigned_projects, optional: true

  before_save  :update_duration
  after_create :notify_cas_manager_new_cas_project_saved
  after_save   :reset_project_data_items
  after_save   :destroy_project_datasets_without_any_levels

  # effectively belongs_to .. through: .. association
  # delegate :dataset,      to: :team_dataset, allow_nil: true
  delegate :organisation, to: :team

  with_options prefix: true, allow_nil: true do
    delegate :name,            to: :project_type
    delegate :translated_name, to: :project_type
    delegate :name,            to: :team
    delegate :full_name,       to: :owner
    delegate :full_name,       to: :assigned_user
  end

  delegate :supports_pdf_import?, to: :project_type
  delegate :project?, :eoi?, :application?, :cas?, to: :project_type_inquirer

  with_options reject_if: :all_blank, allow_destroy: true do
    accepts_nested_attributes_for :project_attachments
    accepts_nested_attributes_for :project_nodes
    accepts_nested_attributes_for :owner_grant, update_only: :true
    accepts_nested_attributes_for :project_datasets, update_only: :true
  end

  validates :name, presence: true, uniqueness: {
    scope:   %i[team_id project_type_id],
    message: 'Name already being used by this Team'
  }, if: -> { project_type_name.in? %w[Project EOI Application] }

  validate :ensure_owner_grant_presence
  validate :ensure_appropriate_assigned_user
  validate :project_should_belong_to_team

  with_options if: -> { project? } do
    validates :data_source_terms_accepted, acceptance: true
    validates :start_data_date, presence: true
    validates :end_data_date, presence: true
    validate  :end_date_after_start_date?
    # TODO: bypass for EOI until someone tells us if we're using free text data_asset_required
    # or multi datasets
    validate :unique_datasets_for_project
  end

  with_options if: -> { eoi? } do
    validates :project_purpose, presence: true
  end

  attr_accessor :pdf_import

  with_options if: -> { odr? } do
    validates :first_contact_date, presence: true, unless: :pdf_import
  end

  # Allow for auditing/version tracking of Project
  has_paper_trail

  scope :active,     -> { joins(:current_state).merge(Workflow::State.not_deleted) }
  scope :not_in_use, -> { joins(:current_state).merge(Workflow::State.inactive) }
  scope :in_use,     -> { joins(:current_state).merge(Workflow::State.active) }

  scope :awaiting_sign_off, -> { joins(:current_state).merge(Workflow::State.awaiting_sign_off) }

  scope :of_type_eoi,         -> { joins(:project_type).merge(ProjectType.eoi) }
  scope :of_type_application, -> { joins(:project_type).merge(ProjectType.application) }
  scope :of_type_project,     -> { joins(:project_type).merge(ProjectType.project) }
  scope :odr_projects,        -> { joins(:project_type).merge(ProjectType.odr) }
  scope :odr_mbis_projects, -> { joins(:project_type).merge(ProjectType.odr_mbis) }

  scope :owned_by, ->(user) { joins(:grants).where(
                              grants: { roleable: ProjectRole.owner, user_id: user.id }) }
  scope :contributors, ->(user) { joins(:grants).where(
                                  grants: { roleable: ProjectRole.can_edit, user_id: user.id }) }

  scope :cas_dataset_approval, lambda { |user, approved_values = [nil, true, false]|
    where(id: ProjectDataset.dataset_approval(user, approved_values).pluck(:project_id)).order(:id).
      joins(:current_state).merge(Workflow::State.dataset_approval_states)
  }

  scope :cas_access_approval, lambda {
    joins(:current_state).where(workflow_current_project_states: { state_id: 'SUBMITTED' }).
      joins(:project_type).merge(ProjectType.cas)
  }

  accepts_nested_attributes_for :project_attachments

  after_transition_to :status_change_notifier

  before_validation :add_datasets_for_clone
  before_save :nullify_blank_lookups

  DATA_SOURCE_ITEM_NO_CLONE_FIELDS = %w[id project_id project_data_source_item_id].freeze

  attr_searchable :name,                  :text_filter
  attr_searchable :application_log,       :application_log_filter # Meh.
  attr_searchable :project_type_id,       :default_filter
  attr_searchable :assigned_user_id,      :default_filter
  attr_searchable :owner,                 :association_filter, kwargs: true # FIXME: See Searchable
  attr_searchable :current_project_state, :association_filter

  class << self
    def unassigned(check_temporal: false)
      return where(assigned_user: nil) unless check_temporal

      joins(:current_project_state).
        where(
          assigned_user: nil,
          workflow_current_project_states: { assigned_user_id: nil }
        )
    end

    def assigned(check_temporal: false)
      return where.not(assigned_user: nil) unless check_temporal

      base = joins(:current_project_state)
      base.where.not(assigned_user: nil).or(
        base.where.not(workflow_current_project_states: { assigned_user_id: nil })
      )
    end

    def assigned_to(user, check_temporal: false)
      return where(assigned_user: user) unless check_temporal

      base = joins(:current_project_state)
      base.where(assigned_user: user).or(
        base.where(workflow_current_project_states: { assigned_user_id: user })
      )
    end

    private

    # Custom search filter.
    # Legacy data... computed fields... desire to search on magic strings rather than the actual
    # underyling data...
    # NOTE: Expect edge cases where this may not produce the anticipated results.
    def application_log_filter(_field, value)
      return if value.blank?

      string = value.to_s.strip
      filter = arel_table[:application_log].matches("%#{string}%")

      return filter unless match ||= string.match(
        %r(\A(?<head>ODR_?(?<fy_start>\d{2})(?<fy_end>\d{2})_?)?(?<id>\d+)?(?<tail>/.*)?\z)i
      )

      chain = []
      chain << arel_table[:first_contact_date].gteq("20#{match[:fy_start]}-04-01") if match[:fy_start]
      chain << arel_table[:first_contact_date].lteq("20#{match[:fy_end]}-03-31")   if match[:fy_end]
      chain << arel_table[:id].eq(match[:id].to_i) if match[:id]

      filter.or(
        Arel::Nodes::Grouping.new(
          chain.reduce(chain.shift) { |node, predicate| node.and(predicate) }
        )
      )
    end
  end

  def organisation_name
    super || organisation&.name
  end

  def application_date
    super || created_at || Time.zone.now
  end

  def duration
    super || calculate_duration_in_months
  end

  def classification_names
    classifications.map(&:name)
  end

  def end_use_names
    end_uses.map(&:name)
  end

  # TODO: Do we need this here? Can we move this to `State` instead?
  # e.g. `project.current_state.submitted?`
  def submitted?
    current_state.id != 'DRAFT'
  end

  # TODO: Do we need this here? Can we move this to `State` instead?
  # e.g. `project.current_state.rejected?`
  def rejected?
    current_state.id == 'REJECTED'
  end

  def reset_approvals
    # using update column here as dont want to fire status change - only accesible for odr
    update_columns(details_approved: nil, members_approved: nil, legal_ethical_approved: nil)
    ProjectDataSourceItem.where(project_id: id).update_all(approved: nil)
  end

  def data_source_item_ids
    nodes.map(&:id)
  end

  def data_source_item_ids=(ids)
    self.nodes =
      available_data_source_items.find_all { |di| Array(ids).map(&:to_i).include? di.id }
  end

  def available_data_source_items
  # TODO: hook up dataset_version
    dataset_version_ids = datasets.flat_map { |d| d.dataset_versions.last.id }
    data_items = Nodes::DataItem.where(dataset_version_id: dataset_version_ids)
    data_item_groups = Nodes::DataItemGroup.where(dataset_version_id: dataset_version_ids)
    sorted_items = data_items.reject do |item|
      data_item_groups.pluck(:name).include? item.parent_node.name
    end

    (sorted_items + data_item_groups).sort_by(&:dataset_version_id)
  end

  # TODO: remove use of dataset_version.last
  def unselected_available_data_source_items
    selected = project_nodes.collect(&:node_id)
    all = dataset.dataset_versions.last.data_items_and_data_item_groups.collect(&:id)
    dataset.dataset_versions.last.data_items.where(id: all-selected)
  end

  def unjustified_data_items
    project_nodes.count do |a|
      a.governance&.value == 'DIRECT IDENTIFIER' && a.comments.empty?
    end
  end

  # TODO: Deprecated; there's now actual validations.
  def new_project_submission_disabled
    return false if eoi?

    if project_nodes.count.zero? ||
       project_nodes.count != 0 && unjustified_data_items > 0 ||
       members.count.zero?
      'disabled'
    else
      ''
    end
  end

  # Before destroy call back, allows for
  # dependant: :destroy
  def null_senior_user_id
    update_column(:senior_user_id, nil)
  end


  # TODO: Presentation layer logic. No longer relevant? See `project_status_label`
  # get a friendly status message to show to the user
  def friendly_status_message
    case current_state.id
    when 'SUBMITTED'
      'Pending Approval'
    when 'DRAFT'
      'New Project'
    else
      current_state.id
    end
  end

  # get the overall state of the data item approvals
  def data_items_approved
    return nil if project_nodes.count.zero?
    return nil if project_nodes.collect(&:approved).uniq.include?(nil)
    return false if project_nodes.collect(&:approved).uniq.include?(false)

    true
  end

  # is the project in a suitable state to be submitted
  def can_submit_approvals
    return nil if data_items_approved.nil? ||
                  members_approved.nil? ||
                  details_approved.nil? ||
                  legal_ethical_approved.nil?

    data_items_approved && members_approved && details_approved && legal_ethical_approved ? true : false
  end

  # TODO: This is more of a background/scheduled job; do we need the logic here or can we move it
  # to an e.g. Rake task?
  # check for any projects that will expire in the next X days
  def self.check_for_expiring_projects
    of_type_project.in_use.find_each do |project|
      number_of_days_warning = (project.frequency == 'Annually' ? [30, 14, 3, 1] : [14, 3, 1])
      key_dates = number_of_days_warning.map { |a| project.end_data_date - a.days }
      next unless key_dates.include? Time.zone.today
      title = "#{project.name} - Will expire in #{(project.end_data_date - Time.zone.today).to_i} days"
      project.team.delegate_users.each do |delegate|
        Notification.create!(title: title,
                             body: CONTENT_TEMPLATES['email_project_day_expiry']['body'] %
                             { project: project.name,
                               number_of_days: (project.end_data_date - Time.zone.today).to_i,
                               expiry_date: project.end_data_date,
                               data_set: project.datasets.map(&:name).join(' | ') },
                             project_id: project.id,
                             odr_users: true,
                             user_id: delegate.id)
      end
    end
  end

  # TODO: This is more of a background/scheduled job; do we need the logic here or can we move it
  # to an e.g. Rake task?
  # check for projects that have expired today
  def self.check_and_set_expired_projects
    of_type_project.in_use.find_each do |project|
      next unless project.end_data_date < Time.zone.now
      project.transition_to!(Workflow::State.find('EXPIRED'))
      project.team.delegate_users.each do |delegate|
        Notification.create!(title: "#{project.name} - Expired",
                             body: CONTENT_TEMPLATES['email_project_expired']['body'] %
                             { project_name: project.name },
                             project_id: project.id,
                             odr_users: true,
                             user_id: delegate.id)
      end
    end
  end

  # TODO: Decouple Notification/UserNotification creation from the Project persistence layer.
  # Workflow::Model exposes a pub/sub hook that we can leverage for this, or we can shift it to an
  # after_action in Workflow::Controller
  def status_change_notifier
    delegate_approval_needed_notification if current_state.id == 'REVIEW'
    odr_approval_needed_notification if current_state.id == 'SUBMITTED'
    odr_rejected_notification if current_state.id == 'REJECTED'
    odr_approved_notification if current_state.id == 'APPROVED'
  end

  def delegate_approval_needed_notification
    team.delegate_users.each do |delegate|
      delegate_notification =
        Notification.new(title: "#{name} - needs approving",
                         body: CONTENT_TEMPLATES['email_project_delegate_approval_needed']['body'])
      delegate_notification.user_id = delegate.id
      delegate_notification.save!
    end
  end

  def odr_approval_needed_notification
    Notification.create!(title: "#{name} - has been submitted for approval",
                         body: CONTENT_TEMPLATES['email_project_odr_approval_needed']['body'],
                         project_id: id,
                         odr_users: project? ? true : false)
  end

  def odr_rejected_notification
    return unless template ||= CONTENT_TEMPLATES.dig('email_project_odr_approval_decision', 'body')

    Notification.create!(generate_mail: false) do |notification|
      notification.title      = "#{name} - Rejected"
      notification.body       = format(template, project: name, status: current_state.id)
      notification.project_id = id

      notification.users_not_to_notify.merge(users.odr_users.ids) if application?
    end
  end

  def odr_approved_notification
    Notification.create!(title: "#{name} - Approved",
                         body: CONTENT_TEMPLATES['email_project_odr_approved']['body'],
                         project_id: id)
  end

  # TODO: Change/move to report object and optimise.
  def self.report2
    Team.all
    team - project - comments
    all.each do |p|
      projects << { team: p.team.name,
                    division: p.team.division.name,
                    head_of_profession: p.team.division.head_of_profession,
                    delegate_approver: p.team.delegate_users.collect(&:full_name),
                    title: p.name,
                    summary: p.description,
                    status: p.current_state.id,
                    start_date: p.start_data_date,
                    end_date: p.end_data_date,
                    frequency: p.frequency_other.nil? ? p.frequency : p.frequency_other,
                    senior_member: p.senior_user.full_name,
                    members: p.members.collect(&:full_name),
                    data_users: p.project_data_end_users.collect(&:email),
                    end_use: p.end_use_other.nil? ? p.end_use : p.end_use_other,
                    dataset: p.dataset.name,
                    data_items: p.data_items.collect(&:name) }
    end
    projects
  end

  def add_owner_grant
    # don't add if an owner grant already exists
    return if grants.any? { |g| g.roleable == ProjectRole.fetch(:owner) }

    grants << Grant.new(roleable: ProjectRole.fetch(:owner), user: owner)
  end

  def add_previous_owner_as_contributor(user_id)
    # User already was a contributor in a previous life
    return if grants.projects.contributors.map(&:user_id).include? user_id

    Grant.create!(project_id: id, user_id: user_id,
                  roleable: ProjectRole.fetch(:contributor))
  end

  def remove_current_owner_as_contributor(user_id)
    # User did not previously have a contributor grant to remove OR
    # We are creating a project
    return if grants.projects.contributors.map(&:user_id).exclude? user_id

    Grant.find_by(project_id: id, user_id: user_id,
                  roleable: ProjectRole.fetch(:contributor)).destroy
  end

  # If a project type can only select one dataset then add it by default
  def add_default_dataset
    return unless project_type.datasets.length == 1

    datasets.push project_type.datasets.first
  end

  # return children of any data_item_groups
  def all_data_items
    return nodes unless nodes.any? { |node| node.type ==  'Nodes::DataItemGroup' }

    item_groups = nodes.where(type: 'Nodes::DataItemGroup')
    items = nodes - item_groups
    item_groups.each do |group|
      items += group.child_nodes
    end
    items
  end

  def odr?
    eoi? || application?
  end

  def closed?
    current_state&.id == 'REJECTED'
  end

  def dataset_names
    datasets.map(&:name)
  end

  # display this but for all intent and purposes project.id is all that is needed to link
  # eois and applications together
  def application_log
    return super if super.present?
    return unless odr?
    return unless first_contact_date

    fy_start, fy_end = financial_year(first_contact_date).minmax.map! do |date|
      date.strftime('%y')
    end

    "ODR#{fy_start}#{fy_end}_#{id}"
  end
  alias reference application_log

  def next_amendment_reference
    return unless odr?
    return unless application_log

    "#{application_log}/A#{amendment_number + 1}"
  end

  private

  def project_type_inquirer
    return false unless project_type

    project_type.name.downcase.inquiry
  end

  # If the data source is changed, remove any
  # previously sleected data items
  # TODO: unit test. test only one dataset items destroyed if removed and comments are destroyed
  def reset_project_data_items
    # Do any nodes belong to a dataset that is no longer associated with project
    return unless project_nodes.any? { |project_node| datasets.exclude? project_node.node.dataset }
    project_nodes.each do |project_node|
      project_node.destroy if datasets.exclude? project_node.node.dataset
    end
  end

  def notify_cas_manager_new_cas_project_saved
    return unless cas?

    User.cas_managers.each do |user|
      CasNotifier.new_cas_project_saved(self, user.id)
    end

    CasMailer.with(project: self).send(:new_cas_project_saved).deliver_later
  end

  def senior_user_must_be_active
    return if senior_user.nil?
    return unless senior_user.flagged_as_deleted?

    errors.add(:senior_user_id, 'is flagged as deleted!')
  end

  def end_date_after_start_date?
    return unless end_data_date.present? && start_data_date.present?
    return unless end_data_date < start_data_date

    errors.add :end_data_date, "must be after start date"
  end

  def user_delegate?(team, userid)
    team.delegate_user_ids.include? userid
  end

  def clone_project_sub_details
    return unless clone_of.presence

    existing = Project.find(clone_of)
    update_attribute(:data_source_item_ids, existing.data_source_item_ids)
    clone_data_source_items_and_associated_comments(existing)
    clone_other_items(existing)
  end

  def clone_other_items(existing)
    multi_fields = %i[end_uses classifications outputs]
    multi_fields.each { |field| update_attribute(field, existing.send(field)) }
  end

  def clone_data_source_items_and_associated_comments(existing)
    transaction do
      # find the original comment attached to a data source item and copy if present
      data_items.each do |dsi|
        existing_item = existing_comment(existing, dsi)
        next if existing_item.comments.blank?

        project_node = project_nodes.find_by(node: dsi)
        next if project_node.nil?

        # make a new comment based on original project
        existing_item.comments.each do |item_comments|
          project_node.comment.create!(
            user: item_comments.user,
            body: item_comments.body,
            tags: item_comments.tags
          )
        end
      end
    end
  end

  def existing_comment(existing, data_item)
    existing_data_item = existing.data_items.find_by(name: data_item.name)
    ProjectNode.find_by(project_id: existing.id, node_id: existing_data_item.id)
  end

  def ensure_appropriate_assigned_user
    return if assigned_user.blank?

    application_manager = assigned_user.application_manager? ||
                          assigned_user.senior_application_manager?
    return if application_manager && assigned_user.flagged_as_active?

    errors.add :assigned_user, :invalid
  end

  def ensure_owner_grant_presence
    return if owner_grant

    errors.add(:owner_grant, 'Owner must be present')
  end

  def unique_datasets_for_project
    return errors.add(:project_datasets, 'no datasets for project') if project_datasets.blank?

    # Use #tally in ruby 2.7
    counts = project_datasets.map(&:dataset_id).each_with_object(Hash.new(0)) { |l, c| c[l] += 1 }
    return unless counts.any? { |_id, count| count > 1 }

    errors.add(:project_datasets, 'Duplicate datasets selected for project')
  end

  # If the current user is creeting a project on behalf of someone else, they would not be
  # owner and therefore are denied access to the project they just created  as they do not
  # have a project grant. e.g ODR application managers
  def add_current_user_as_contributor(user)
    # Owner is the current user. Do nothing
    return if user == owner_grant.user

    grants << Grant.new(roleable: ProjectRole.fetch(:contributor), user: user)
  end

  # bit of hack for cloning
  def add_datasets_for_clone
    return unless clone_of.presence
    return if persisted?
    # TODO: I'm not sure we should be cloninng this. perhaps turn off validation if clone_of

    Project.find(clone_of).datasets.each_with_object(project_datasets) do |d, pd|
      pd << ProjectDataset.new(dataset: d, terms_accepted: true)
    end
  end

  # TODO: We should port NDTSMv2 BelongToLookup at some point
  # Postgres Foreign key validation failures for ""
  def nullify_blank_lookups
    source_names = %i[data_processor_country_id funder_country_id sponsor_country_id]
    source_names.each do |attribute|
      send("#{attribute}=", nil) if send(attribute).blank?
    end
  end

  def project_should_belong_to_team
    return if cas?
    return if team

    errors.add(:project, 'Must belong to a Team!')
  end

  def destroy_project_datasets_without_any_levels
    return unless cas?
    return unless project_datasets.any?

    project_datasets.each do |pd|
      pd.destroy if pd.project_dataset_levels.none?
    end
  end

  def financial_year(date)
    start_year = date.month < 4 ? date.year - 1 : date.year

    Date.new(start_year, 4, 1)..Date.new(start_year + 1, 3, 31)
  end

  def calculate_duration_in_months
    return unless start_date ||= self[:start_data_date]
    return unless end_date   ||= self[:end_data_date]

    delta  = (end_date.year * 12 + end_date.month) - (start_date.year * 12 + start_date.month)
    offset = start_date.day > end_date.day ? -1 : 0

    delta + offset
  end

  # NOTE: ODR want to use `duration` to confirm end date has been corractly calculated.
  def update_duration
    return if duration_changed? # Avoid feedback loop...
    return unless (changed_attributes.keys & %w[start_data_date end_data_date]).any?
    return unless new_duration ||= calculate_duration_in_months

    self.duration = new_duration
  end
end
