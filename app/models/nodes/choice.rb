module Nodes
  # Handle choices
  # Nodes that are part of a choice must be mandatory i.e minoccurs == 1
  class Choice < Node
    include Xsd::Generator

    belongs_to :node, class_name: 'Node', foreign_key: 'parent_id',
                      optional: true, inverse_of: :data_items
    belongs_to :entity, class_name: 'Nodes::Entity', foreign_key: 'parent_id',
                        optional: true, inverse_of: :choices
    belongs_to :choice_type, class_name: 'ChoiceType', foreign_key: 'choice_type_id',
                             inverse_of: :choices
    # TODO: keep normal inverse here
    has_many :child_nodes, class_name: 'Node', foreign_key: 'parent_id',
                           dependent: :delete_all, inverse_of: :choice
    has_many :data_items, class_name: 'Nodes::DataItem', foreign_key: 'parent_id',
                          inverse_of: :choice
    accepts_nested_attributes_for :data_items, reject_if: :all_blank, allow_destroy: true
    has_many :entities, class_name: 'Nodes::Entity', foreign_key: 'parent_id',
                        inverse_of: :choice
    accepts_nested_attributes_for :entities, reject_if: :all_blank, allow_destroy: true

    before_save :define_min_occurs
    before_save :define_max_occurs

    validate :min_occurs_required_for_choice_type, on: :publish
    validate :choice_must_have_child_nodes, on: :publish
    validate :only_one_choice_available, on: :publish
    validate :number_of_choices_should_not_be_less_max_occurs, on: :publish

    # If choice is not optional it is mandatory and min_occurs should be defined by user
    def define_min_occurs
      self.min_occurs = choice_type_min_occurs
    end

    def define_max_occurs
      self.max_occurs = choice_type_max_occurs
    end

    def choice_type_min_occurs
      return 0 if choice_type.optional?
      return 1 if choice_type.mandatory?
      return min_occurs if choice_type.mandatory_multiple?
    end

    def choice_type_max_occurs
      return nil if choice_type.unbounded?
      return min_occurs if choice_type.single_choice? && min_occurs > 1
      return 1 if choice_type.single_choice?
      child_nodes.length
    end

    def min_occurs_required_for_choice_type
      return unless choice_type
      error_msg = 'Minimum occurrences must be defined if multiple mandatory options are allowed'
      errors.add(:choice, error_msg) if
        choice_type.mandatory_multiple? && min_occurs.nil?
    end

    def choice_must_have_child_nodes
      errors.add(:choice, 'Choice must have some choices!') if child_nodes.blank?
    end

    def only_one_choice_available
      errors.add(:choice, 'Only one choice available for choice') if child_nodes.length == 1
    end

    def number_of_choices_should_not_be_less_max_occurs
      return if max_occurs.nil?
      errors.add(:choice, 'not enough choices for allowed choice max_occurs') if
        child_nodes.length < max_occurs
    end

    # entity part of a choice which belongs to a group, AND the entity has specific items
    def to_xsd(schema, category = nil)
      return unless node_for_category?(category)
      options = {
        minOccurs: min_occurs.to_s,
        maxOccurs: max_occurrences
      }
      xsd_choice(schema, options) do |choice_element|
        child_nodes.sort_by(&:sort).each do |node|
          node.to_xsd(choice_element, category)
        end
      end
    end

    # Two situations
    # 1) A Choice could only be valid for one category
    # 2) A Choice could contain nodes that are not valid for all categories
    def to_xml(xml, category = nil)
      return unless node_for_category?(category)
      # not all choices are valid for category
      return if choices_for_category(category).blank?
      choice = choices_for_category(category).sample
      choice.to_xml(xml, category)
    end

    def to_xml_choice(options)
      category = options[:category]&.name
      return unless node_for_category?(category)

      # not all choices are valid for category
      return if choices_for_category(category).blank?

      # IF not part of a dataset using categories e.g SACT
      chosen = options[:choice].nil? ? random_sample : category_sample(options)
      chosen.each { |node| node.to_xml_choice(options) }
    end

    def random_sample
      Array(child_nodes.sample)
    end

    def category_sample(options)
      # If I'm a choice that contains a choice down the line of the choice in question,
      # then make the required choice
      # Required choice
      chosen = Array(options[:choice]).select { |node| node.id.in? child_nodes.pluck(:id) }
      sample_msg = "#{name} choice example #{options[:choice_no]}" if chosen.present?
      options[:xml].comment sample_msg if chosen.present?
      # Parent choice
      chosen = Array(options[:parent_choices][id]) if chosen.blank?
      # not part of path, nake random choice
      chosen = Array(choices_for_category(options[:category]&.name).sample) if chosen.blank?
      chosen
    end

    def valid_choice_combinations
      return child_nodes if max_occurs.eql?(1)

      # Also include no choice as an example
      return child_nodes.to_a.combination(1).to_a << [] if min_occurs.eql?(0)

      mandatory_choice_combinations
    end

    def mandatory_choice_combinations
      combos = []
      (min_occurs..max_occurs).each do |no_of_choices|
        combos += child_nodes.to_a.combination(no_of_choices).to_a
      end
      combos
    end

    # TODO: Double check this hasn't broken anything
    def categories_for_sample_choice
      # categories.presence || dataset_version.categories.where(name: 'Other')
      categories.presence || [dataset_version.core_category]
    end

    private

    # only choose from nodes that belong to the category if applicable
    def choices_for_category(category)
      child_nodes.sort_by(&:sort).each_with_object([]) do |node, filtered|
        filtered << node if node.node_for_category?(category)
      end
    end
    
    def choice_text
      if min_occurs == max_occurrences
        "Exactly #{min_occurs} MUST be present"
      elsif min_occurs.positive? && min_occurs != max_occurrences
        "At least #{min_occurs} of the following #{max_occurrences} MUST be present"
      elsif min_occurs.positive?
        "Only #{min_occurs} of the following #{max_occurrences} must be present"
      elsif min_occurs.zero? && max_occurrences.present?
        "Only #{max_occurs} occurrence(s) of each the following can be present"
      end
    end
  end
end
