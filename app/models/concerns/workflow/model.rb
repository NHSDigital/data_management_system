module Workflow
  # Contains workflow related behaviour for the `Project` model.
  module Model
    extend ActiveSupport::Concern

    # Specify custom workflow entry points here (if required). The hash should be keyed by
    # `project_type_name` and values should by `State` ids (e.g. 'Project' => 'NEW').
    DEFAULT_ENTRY_POINT = 'DRAFT'.freeze
    CUSTOM_ENTRY_POINTS = {}.freeze

    TRANSITION_EVENT = 'transition.project'.freeze

    included do
      has_many :project_states, inverse_of: :project, dependent: :destroy,
                                class_name: 'Workflow::ProjectState'

      has_many :states, through: :project_states, class_name: 'Workflow::State'

      has_one :current_project_state, inverse_of: :project,
                                      class_name: 'Workflow::CurrentProjectState'

      has_one :current_state, through: :current_project_state, source: :state,
                              class_name: 'Workflow::State'

      has_many :transitionable_states, ->(project) {
        merge(Transition.applicable_to(project.project_type)).
        merge(Transition.previous_state_before_closure(project))
      }, through: :current_state, class_name: 'Workflow::State'

      scope :in_progress, -> { joins(:current_state).merge(State.non_terminal) }
      scope :finished,    -> { joins(:current_state).merge(State.terminal) }

      define_model_callbacks :transition_to

      before_create :initialize_workflow
      before_transition_to -> { project_states.reset }
      around_transition_to :publish_state_change
      around_transition_to :refresh_current_state
      after_transition_to  :reset_approval_fields

      validate :ensure_ready_for_transition, on: :transition
    end

    def initialize_workflow(user = nil)
      return if project_states.any?
      return unless state ||= workflow_entry_point

      project_states.build(state: state, user: user)
    end

    # The transition methods should be used as the primary method for shifting `project` from one
    # `state` to another. Should you choose to manipulate the `project_states` collection directly
    # then you are responsible for ensuring `current_state` and `transitionable_states` are not
    # stale.
    def transition_to!(state, user = nil)
      transaction do
        run_callbacks :transition_to do
          project_state = project_states.build(state: state, user: user)
          yield(self, project_state) if block_given?
          save!(context: :transition)
        end
      end
    end

    def transition_to(state, user = nil, &block)
      transition_to!(state, user, &block)
    rescue
      false
    end

    # i.e. is it appropriate to show a button in the UI:
    def can_transition_to?(state)
      transitionable_states.exists?(state.id) && reasons_not_to_transition_to(state).none?
    end

    def textual_reasons_not_to_transition_to(state)
      # ... yuk
      reasons_not_to_transition_to(state).map do |attr, reason|
        message = errors.send(:normalize_message, attr, reason, {})
        errors.send(:full_message, attr, message)
      end
    end

    def previous_state
      return if project_states.blank?

      project_states.order(:created_at, :id)[-2]
    end

    def previous_state_id
      previous_state&.state_id
    end

    private

    # To set specific critera for a given state, define
    # e.g. `reasons_not_to_transition_to_dpia_approval`
    # Returns empty list if no specific critera can be evaluated.
    def reasons_not_to_transition_to(state)
      method = :"reasons_not_to_transition_to_#{state.id.downcase}"
      return {} unless respond_to?(method, true)

      with_target_state(state) { send(method) }
    end

    def workflow_entry_point
      State.find_by(id: CUSTOM_ENTRY_POINTS.fetch(project_type_name, DEFAULT_ENTRY_POINT))
    end

    def refresh_current_state(*)
      yield
      reload_current_state
      transitionable_states.reset
    end

    # Use pub/sub to provide a means for any interested parties to respond to the change of state.
    def publish_state_change
      state_was = current_state
      yield
      state_now = current_state

      return if state_was == state_now

      payload = { project: self, transition: [state_was, state_now] }
      ActiveSupport::Notifications.instrument TRANSITION_EVENT, payload
    end

    def reset_approval_fields
      return unless current_state == workflow_entry_point
      return if project_states.count == 1

      transaction do
        project_nodes.update_all(approved: nil)
        update!(
          details_approved: nil,
          members_approved: nil,
          legal_ethical_approved: nil,
          closure_reason: nil
        )
      end
    end

    def reasons_not_to_transition_to_review
      unjustified_data_items.positive? ? { data_items: :unjustified } : {}
    end

    def reasons_not_to_transition_to_dpia_review
      return {} if dpias.joins(:attachment).exists?

      { base: :no_attached_dpia }
    end

    def reasons_not_to_transition_to_contract_draft
      return {} if contracts.joins(:attachment).exists?

      { base: :no_attached_contract }
    end

    def reasons_not_to_transition_to_submitted
      # Eventually this may apply to all project/application types
      return {} unless cas? && current_state.id == 'DRAFT'
      return {} if all_cas_user_fields_present?

      { base: :user_details_not_complete }
    end

    def transition_blocking_approval_reasons
      return {} unless project? && current_state.id == 'SUBMITTED'

      approvals = [details_approved, members_approved, legal_ethical_approved, data_items_approved]

      if approvals.none? && target_state.id == 'APPROVED'
        { base: :not_approvable }
      elsif approvals.any?(&:nil?)
        { base: :outstanding_approvals }
      else
        {}
      end
    end

    alias reasons_not_to_transition_to_rejected transition_blocking_approval_reasons
    alias reasons_not_to_transition_to_approved transition_blocking_approval_reasons

    def ensure_ready_for_transition
      state = target_state
      return unless state

      reasons = reasons_not_to_transition_to(state)
      reasons.each { |attr, reason| errors.add(attr, reason) }
    end

    def target_state
      @target_state || project_states.detect(&:new_record?)&.state
    end

    def with_target_state(state)
      old_value = @target_state
      @target_state = state
      yield
    ensure
      @target_state = old_value
    end

    def all_cas_user_fields_present?
      cas_account_fields = User::CAS_ACCOUNT_FIELDS

      unless owner.send(:employment) == 'Permanent'
        cas_account_fields += %i[contract_start_date contract_end_date]
      end
      cas_account_fields.all? { |field| owner.send(field).present? }
    end
  end
end
