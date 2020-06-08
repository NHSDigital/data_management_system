module DatasetVersionHelper
  def ancestors(parent)
    ancestor_array = []

    while parent = parent.parent_node
      ancestor_array << parent
    end

    ancestor_array
  end

  def render_tree(root, selected_node = nil, ancestors = [], depth = 0)
    # return unless ancestors.include?(root) || root == selected_node || root.parent_node == selected_node

    html = render('nodes/tree_details',
                  node: root, depth: depth, ancestor: ancestors.include?(root),
                  selected_node: selected_node)
    root.child_nodes.sorted.each do |node|
      next if node.data_item?

      html += render_tree(node, selected_node, ancestors, depth + 1)
    end
    html
  end

  def dataset_download_link(from_tree = true)
    return unless @dataset_version.dataset.dataset_type.name == 'xml'
    return unless can?(:download, DatasetVersion)

    link_class = action_link_class(from_tree)

    link_to('Download', dataset_version_download_path(@dataset_version, @dataset_version),
            class: link_class, 'data-turbolinks' => false, id: 'publish')
  end

  def publish_tr_class(v)
    return 'danger' unless v.published
  end

  def publish_link(from_tree = true)
    return published_state_button if @dataset_version.published
    return unless can?(:publish, DatasetVersion)

    link_class = action_link_class(from_tree)

    link_to('Publish', publish_dataset_version_path(@dataset_version), method: :patch,
            class: link_class, 'data-turbolinks' => false, id: 'publish')
  end

  def published_state_button
    button_tag('Published', class: 'btn btn-sm btn-info')
  end

  def action_link_class(from_tree = true)
    if from_tree
      'btn btn-sm btn-success'
    elsif @dataset_version.send(:invalid_nodes_for_schema_build).present?
      'btn btn-sm btn-danger'
    else
      'btn btn-sm btn-success'
    end
  end

  def dataset_versions_for_user(dataset)
    dataset.dataset_versions.order('semver_version').reverse.each_with_object([]) do |dv, list|
      list << dv if can?(:read, dv)
    end
  end

  def dataset_type_label(dataset)
    content_tag(:span, dataset.dataset_type_name, class: 'label label-primary')
  end

  def child_node_table_id(dataset_version)
    return unless can?(:update, dataset_version)
    return if dataset_version.published

    'table-child-nodes-sortable'
  end
end
