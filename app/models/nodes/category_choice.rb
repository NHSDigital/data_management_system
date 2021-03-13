module Nodes
  # In reality the only place we can see this being used is {Group}Record choice in COSD
  class CategoryChoice < Node
    include Xsd::Generator

    belongs_to :node, class_name: 'Node', foreign_key: 'parent_id',
                      optional: true, inverse_of: :data_items
    belongs_to :entity, class_name: 'Nodes::Entity', foreign_key: 'parent_id',
                        optional: true, inverse_of: :category_choices
    # TODO: keep normal inverse here
    has_many :child_nodes, class_name: 'Node', foreign_key: 'parent_id',
                           dependent: :destroy, inverse_of: :category_choice

    def xsd_name(xsd_type, name, category)
      Nodes::DatasetVersionLookup.lookup(dataset_version, xsd_type, name, category)
    end

    # entity part of a choice which belongs to a group, AND the entity has specific items
    def to_xsd(schema, _category)
      options = {
        minOccurs: min_occurs.to_s,
        maxOccurs: max_occurrences
      }
      xsd_choice(schema, options) do |choice_element|
        child_nodes.sort_by(&:sort).each do |child_node|
          dataset_version.categories.sort_by(&:sort).each do |category|
            # TODO: we're not expecting to do anything else here but this is hard coded behaviour
            name_and_type = category.name + child_node.name
            entity_options = { name: name_and_type,
                               type: xsd_name(:type_name, child_node.name, category.name),
                               minOccurs: min_occurs, maxOccurs: max_occurrences }
            build_element(choice_element, :element, entity_options)
          end
        end
      end
    end

    # Build an example of every category
    def to_xml(xml, category = nil)
      dataset_version.categories.sort_by(&:sort).each do |category|
        child_nodes.each do |node|
          xml.send(category.name + node.name) do
            node.child_nodes.sort_by(&:sort).each do |child_node|
              child_node.to_xml(xml, category.name)
            end
          end
        end
      end
    end

    # TODO: some choices don't have a category and rely on the parent_node.
    # This breaks schema if adding to category to choice - investigate.
    # currently handled by node_categories in Node.rb
    def to_xml_choice(options)
      return if dataset_version.choices.blank?

      samples_for(dataset_version.choices, options)
    end

    private

    def samples_for(choices, options)
      choices.each do |choice|
        parent_choices = choice.parent_choices_to_get_to_this_choice
        choice.valid_choice_combinations.each.with_index(1) do |combination, i|
          # For each choice make the simplest valid sample xml record possible
          choice.categories_for_sample_choice.each do |category|
            node_options = { xml: options[:xml], category: category, choice: combination,
                             parent_choices: parent_choices, choice_no: i }
            build_child_node_samples(options, node_options)
          end
        end
      end
    end

    def build_child_node_samples(options, node_options)
      child_nodes.sort_by(&:sort).each do |node|
        # Record node
        options[:xml].send(node_options[:category].name + node.name) do
          node.child_nodes.sort_by(&:sort).each do |child_node|
            child_node.to_xml_choice(node_options)
          end
        end
      end
    end
  end
end
