# form Helper methods for Node
module NodesHelper
  NODE_TYPES = %w[DataItem Entity Group Choice CategoryChoice].freeze

  def new_node_dropdown_button(dataset_version, parent_node, **html_options)
    return unless can?(:create, Node.new(dataset_version: @dataset_version))
    options = { class: 'btn btn-primary dropdown-toggle', data: { toggle: :dropdown } }
    options.merge!(html_options)

    menu = capture do
      content_tag(:ul, class: 'dropdown-menu') do
        NODE_TYPES.each do |node_type|
          path = "new_dataset_version_#{node_type.underscore}_path"
          link = link_to(friendly_new_node_name(dataset_version, node_type),
                         send(path, dataset_version, parent_id: parent_node), remote: true)
          concat content_tag(:li, link)
        end
      end
    end

    button = button_tag(bootstrap_icon_tag('plus') + ' New Node', options)

    button_group { safe_join([button, menu]) }
  end

  def edit_node(node)
    return edit_data_item_path(node) if node.data_item?
    return edit_entity_path(node) if node.entity?
    return edit_category_choice_path(node) if node.category_choice?
    return edit_choice_path(node) if node.choice?
    return edit_group_path(node) if node.group?
  end

  def edit_node_error(node)
    return edit_error_data_item_path(node) if node.data_item?
    return edit_error_entity_path(node) if node.entity?
    return edit_error_category_choice_path(node) if node.category_choice?
    return edit_error_choice_path(node) if node.choice?
    return edit_error_group_path(node) if node.group?
  end

  def detail_node(node)
    return data_item_path(node) if node.data_item?
    return entity_path(node) if node.entity?
    return category_choice_path(node) if node.category_choice?
    return choice_path(node) if node.choice?
    return group_path(node) if node.group?
  end

  # TODO: This should show other Dictionary info e.g Group
  def data_dictionary
    DataDictionaryElement.pluck(:name).uniq.sort
  end

  def node_type_label(node)
    label_class = "label label-#{friendly_label_class(node)}"
    content_tag(:span, friendly_node_name(node), class: label_class)
  end

  # Available nodes for a version that could be selected for a choice
  def version_nodes(version)
    (version.nodes - [version.version_entity]).map(&:name)
  end

  def friendly_node_name(node)
    dataset_type = node.dataset.dataset_type_name
    i18n_scope   = [:dataset_type, dataset_type.to_sym, :nodes]
    i18n_key     = node.model_name.element
    t(i18n_key, scope: i18n_scope, default: i18n_key)
  end

  def friendly_new_node_name(dataset_version, node_type)
    dataset_type = dataset_version.dataset.dataset_type_name
    i18n_scope   = [:dataset_type, dataset_type.to_sym, :nodes]
    i18n_key     = node_type.underscore
    t(i18n_key, scope: i18n_scope, default: i18n_key)
  end

  # TODO: Move to en.yml
  def friendly_label_class(node)
    return 'server' if friendly_node_name(node) == 'Server'
    return 'entity' if node.model_name.element == 'database'

    node.model_name.element
  end

  def era_fields_link(node)
    return if node.era_fields.nil?
    return unless can? :read, EraFields

    hide_div_id = "'#era_fields_#{node.id}'"
    td_link = content_tag(:a, 'Show Encore Fields', onclick: '$(' + hide_div_id + ').toggle();')
    content_tag(:tr) do
      content_tag(:td, td_link, colspan: 5)
    end
  end

  def era_fields_detail(node)
    return if node.era_fields.nil?
    return unless can? :read, EraFields

    content_tag(:tbody, id: "era_fields_#{node.id}", style: 'display:none') do
      era_display_fields.each do |field|
        val = node.era_fields.send(field)
        val = val.join(' ') if val.is_a?(Array)
        display_name = t(:era_fields, scope: nil)[field]
        row = content_tag(:tr) do
          concat content_tag(:td, content_tag(:strong, display_name), colspan: 2, align: :right)
          concat content_tag(:td, val, colspan: 3)
        end
        concat row
      end
    end
  end

  private

  def era_display_fields
    %i[ebr ebr_rawtext_name ebr_virtual_name event event_field_name lookup_table comments]
  end
end
