require 'test_helper'

class CanManageDataItemsTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin_user)
    login_and_accept_terms(@admin)
  end

  test 'can create and edit a data item' do
    dataset = Dataset.find_by(name: 'Deaths Gold Standard')
    dataset_version = dataset.dataset_versions.find_by(semver_version: '1.0')
    visit dataset_version_path(dataset_version)
    assert page.has_content?('Deaths Gold Standard')
    
    assert page.has_content?(dataset_version.entities.first.name)

    find_button('New Node').click
    find_link('Data Item').click

    within_modal do
      fill_in 'Name',        with: 'New Item'
      fill_in 'Min Occurs',  with: 1
      fill_in 'Max Occurs',  with: 2
      fill_in 'Description', with: 'New Item Description'
      check 'add-governance'
      select 'INDIRECT IDENTIFIER', from: 'nodes_data_item_governance_id'
      find_button('Save').click
    end

    assert page.has_content?('New Item Description')
    assert_text('Data Item', count: 1)

    data_item = dataset_version.data_items.find_by!(name: 'New Item')
    version_entity_id = "#nodes_entity_#{dataset_version.version_entity.id}_child_node_table"
    within(version_entity_id + " #nodes_data_item_#{data_item.id}") do
      click_link('Edit')
    end

    within_modal do
      fill_in 'Name', with: 'Changed the item name'
      find_button('Save').click
    end

    assert page.has_content?('Changed the item name')

    # Delete data item
    assert_difference('Node.count', -1) do
      new_item = dataset_version.data_items.find_by(name: 'Changed the item name')
      within("#nodes_data_item_#{new_item.id}") do
        accept_prompt do
          click_link('Delete')
        end
      end
      assert page.has_no_content?('New Item Description')
      assert_no_text('Data Item')
    end

    # 5 data items should remain
    click_on('Deceased_Birth', match: :first)
    assert_text('Data Item', count: 5)
    # Delete a data item currently being used in a project
    accept_prompt do
      find('tr', text: 'DOBYR').click_link('Delete')
    end

    assert_text('Data Item', count: 5)
  end

  test 'can add an entity node to existing dataset version' do
    dataset = Dataset.find_by(name: 'Deaths Gold Standard')
    dataset_version = dataset.dataset_versions.find_by(semver_version: '1.0')

    visit dataset_version_path(dataset_version)
    assert page.has_content?('Deaths Gold Standard')
    assert_no_text('Data Item')
    assert_text('Entity')

    find_button('New Node').click
    find_link('Entity').click

    within_modal do
      fill_in 'Name',        with: 'New Entity'
      fill_in 'Min Occurs',  with: 1
      fill_in 'Max Occurs',  with: 2
      find_button('Save').click
    end

    assert page.has_content?('New Entity')

    created_entity = dataset_version.entities.find_by(name: 'New Entity')
    created_entity_id = "#nodes_entity_#{created_entity.id}"
    within(created_entity_id) do
      find_link('Edit', match: :first).click
    end

    within_modal do
      fill_in 'Name', with: 'Changed the Entity name'
      find_button('Save').click
    end

    assert page.has_content?('Changed the Entity name')

    # Delete data item
    assert_difference('Node.count', -1) do
      within(created_entity_id) do
        accept_prompt do
          find_link('Delete').click
        end
      end
      assert page.has_no_content?('Changed the Entity name')
    end
  end

  test 'can create a data item with a data dictionary element' do
    dataset = Dataset.find_by(name: 'Deaths Gold Standard')
    dataset_version = dataset.dataset_versions.find_by(semver_version: '1.0')

    visit dataset_version_path(dataset_version)
    assert page.has_content?('Deaths Gold Standard')
    assert page.has_content?(dataset_version.entities.first.name)

    find_button('New Node').click
    find_link('Data Item').click

    within_modal do
      fill_in 'Name',        with: 'New Data Item With Data Dictionary Element'
      fill_in 'Min Occurs',  with: 1
      fill_in 'Max Occurs',  with: 2
      fill_in 'Description', with: 'New Data Item With Data Dictionary Element Description'
      check 'add-dde'
      fill_in 'search_ddes', with: 'ablat'
      assert page.has_content?('ABLATIVE THERAPY TYPE')
      choose('ABLATIVE THERAPY TYPE')
      find_button('Save').click
    end

    assert page.has_content?('New Data Item With Data Dictionary Element Description')

    created_item =
      dataset_version.data_items.find_by(name: 'New Data Item With Data Dictionary Element')
    assert created_item.data_dictionary_element_id.present?
    created_item_id = "#nodes_data_item_#{created_item.id}"
    assert_difference('Node.count', -1) do
      within(created_item_id) do
        accept_prompt do
          find_link('Delete').click
        end
      end
      assert page.has_no_content?('New Data Item With Data Dictionary Element Description')
      assert page.has_content?('6 Nodes')
    end
  end

  test 'can drag and drop and save sort order' do
    visit dataset_version_path(sact_dataset_version)
    
    record_node = sact_dataset_version.version_entity.child_nodes.first
    assert_equal 'Record', record_node.name
    click_on 'Record', match: :first
    assert has_content? 'Outcome'
    assert has_css?('.table-child-nodes-sortable')

    source_node   = record_node.child_nodes.find_by(name: 'Outcome')
    target_node   = record_node.child_nodes.find_by(name: 'DemographicsAndConsultant')
    adjacent_node = record_node.child_nodes.find_by(name: 'DrugDetails')
    source_node_id   = "body_nodes_entity_#{source_node.id}"
    target_node_id   = "body_nodes_entity_#{target_node.id}"
    adjacent_node_id = "body_nodes_entity_#{adjacent_node.id}"

    within("#nodes_entity_#{record_node.id}_child_node_table") do
      assert has_selector?("tbody##{adjacent_node_id} + tbody##{source_node_id}")
    end

    assert_changes ->{ sact_dataset_version.nodes.find_by(name: 'Outcome').sort }, from: 6, to: 1 do
      within("#nodes_entity_#{record_node.id}_child_node_table") do
        source = find_by_id(source_node_id)
        target = find_by_id(target_node_id)
        source.drag_to(target)
        assert has_no_selector? 'tbody.table-update-sort'
        assert has_selector?("tbody##{source_node_id} + tbody##{target_node_id}")
      end
    end

    # Revisit path and expect order to have saved and visible
    visit current_path

    assert_equal 1, Nodes::Entity.find_by(name: 'Outcome').sort,
                    'Drag and Drop node did not save sort order'
    expected_order =
      %w[Outcome DemographicsAndConsultant ProgrammeAndRegimen Cycle ClinicalStatus DrugDetails]
    assert_equal expected_order, record_node.child_nodes.sort_by(&:sort).map(&:name)
  end

  test 'cannot sort published version' do
    dataset = Dataset.find_by(name: 'Deaths Gold Standard')
    dataset_version = dataset.dataset_versions.find_by(semver_version: '1.0')
    visit dataset_version_path(dataset_version)

    assert has_no_css?('.table-child-nodes-sortable')
  end

  test 'user without abiity cannot drag and drop' do
    sign_in users(:senior_project_user)
    visit dataset_version_path(sact_dataset_version)

    assert has_no_css?('.table-child-nodes-sortable')
  end

  test 'user with abiity can drag and drop' do
    dataset_manager = users(:team_dataset_manager)

    sign_in dataset_manager
    visit dataset_version_path(sact_dataset_version)
    # not part of SACT team
    assert has_no_css?('.table-child-nodes-sortable')
    
    ncras_team_grant = Grant.create!(team: Team.find_by(name: 'NCRAS'),
                                     user: dataset_manager,
                                     roleable: TeamRole.fetch(:dataset_manager))
    visit dataset_version_path(sact_dataset_version)
    assert has_css?('.table-child-nodes-sortable')

    ncras_team_grant.destroy!
  end

  def sact_dataset_version
    @sact_dataset ||= Dataset.find_by(name: 'SACT')
    @sact_dataset_version ||= @sact_dataset.dataset_versions.find_by(semver_version: '2.0')
  end
end
