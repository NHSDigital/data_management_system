namespace :data_source do
  # Attempt to merge existing DataSource and DataSourceItem to Node structure
  # order
  # 1) merge_to_node
  # 2) migrate_team_data_source_to_team_data_set
  # 3) migrate_existing_projects
  
  task merge_to_node: :environment do
    started = Time.zone.now
    print "\nSTARTED => #{started}"
    print "\n#{started}"
    DataSource.transaction do
      mbis = ['Birth Transaction', 'Births Gold Standard',
              'Death Transaction', 'Deaths Gold Standard']
      DataSource.where(name: mbis).each do |ds|
        dataset = Dataset.create!(name: ds.name, full_name: ds.title, terms: ds.terms,
                                  dataset_type: DatasetType.fetch(:non_xml))
        # create a default version
        version = DatasetVersion.create!(dataset_id: dataset.id, semver_version: '1-0')
        parent_node = Nodes::Entity.new(dataset_version: version, name: ds.name, sort: 0,
                                        description: ds.title, min_occurs: 1, max_occurs: 1)
        ds.data_source_items.group_by(&:category).each_with_index do |(category, items), i|
          create_child_nodes(version, category, items, parent_node, i)
        end
        parent_node.save!
        print "\n Created #{parent_node.name} dataset and nodes!"
      end
    end
    finished = Time.zone.now
    print "\nFINISHED => #{finished}"
    print "\nDURATION => #{(finished - started).round(2)} SECONDS\n"
  end

  task migrate_team_data_source_to_team_data_set: :environment do
    counter = 0
    TeamDataSource.all.each do |tds|
      td = TeamDataset.new(team_id: tds.team_id)
      td.dataset = Dataset.find_by(name: tds.data_source.name)
      td.save!
      counter += 1
    end
    print "Migrated #{counter} Team Data Sources to Team Datasets\n"
  end

  task migrate_existing_projects: :environment do
    project_counter = 0
    Project.transaction do
      Project.all.each do |pj|
        next if pj.team_dataset_id.present?
        next if pj.team_data_source_id.nil?
        data_source_id = TeamDataSource.find(pj.team_data_source_id).data_source_id
        new_dataset = Dataset.find_by(name: DataSource.find(data_source_id).name)
        pj.team_dataset = TeamDataset.find_by(dataset_id: new_dataset.id, team_id: pj.team.id)
        pj.save!
        project_counter += 1
      end
    end

    print "Updated #{project_counter} team datasets on Projects\n"

    counter = 0
    ProjectDataSourceItem.all.each do |pdsi|
      data_source_id = TeamDataSource.find(pdsi.project.team_data_source_id).data_source_id
      new_dataset = Dataset.find_by(name: DataSource.find(data_source_id).name)
      pdsi.data_source_item
      project_node = ProjectNode.new
      project_node.project = pdsi.project
      project_node.approved = pdsi.approved
      project_node.created_at = pdsi.created_at
      project_node.updated_at = pdsi.updated_at
      new_node =
        new_dataset.dataset_versions.last.data_items.find_by(name: pdsi.data_source_item.name)
      project_node.node = new_node
      migrate_existing_item_comments(project_node, pdsi)
      project_node.save!
      counter += 1
    end
    print "migrated #{counter} ProjectDataSourceItems to ProjectNode\n"
  end

  def migrate_existing_item_comments(project_node, project_data_source_item)
    return if project_data_source_item.project_comments.blank?
    project_data_source_item.project_comments.each do |original_comment|
      new_comment = ProjectComment.new
      new_comment.project = original_comment.project
      new_comment.user = original_comment.user
      new_comment.comment_type = original_comment.comment_type
      new_comment.comment = original_comment.comment
      new_comment.user_role = original_comment.user_role
      new_comment.created_at = original_comment.created_at
      new_comment.updated_at = original_comment.updated_at
      project_node.project_comments << new_comment
    end
  end

  def create_child_nodes(version, category, items, parent_node, sort)
    entity = Nodes::Entity.create!(name: category, min_occurs: 0, sort: sort,
                                   max_occurs: 1, dataset_version: version)
    items.each_with_index do |item, i|
      n = Nodes::DataItem.new(dataset_version: version, name: item.name,
                              description: item.description, min_occurs: item.occurrences,
                              max_occurs: item.occurrences, sort: i)
      n.governance = Governance.find_by(value: item.governance)
      entity.child_nodes << n
    end
    parent_node.child_nodes << entity
  end
end
