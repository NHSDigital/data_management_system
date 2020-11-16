require 'test_helper'

class VersionControllerTest < ActionDispatch::IntegrationTest
  test 'versions of team are created when created or updated' do
    team = create_team
    assert_equal 1, team.versions.count

    team.update(notes: 'These team notes have changed')
    assert_equal 2, team.versions.count
    expected_change = ['Test Team', 'These team notes have changed']
    assert_equal expected_change, team.versions.last.changeset['notes']
  end

  test 'versions of user are created when created or updated' do
    user = create_user
    assert_equal 1, user.versions.count

    user.update(notes: 'These User notes have changed')
    assert_equal 2, user.versions.count
    expected_change = ['This is a test user', 'These User notes have changed']
    assert_equal expected_change, user.versions.last.changeset['notes']
  end

  test 'versions of project are created when created or updated' do
    project = create_project
    # a second version is created when an association is added (team_data_source)
    assert_equal 1, project.versions.count

    project.update(name: 'NCRS - Updated Project Name')
    assert_equal 2, project.versions.count
    expected_change = ['NCRS', 'NCRS - Updated Project Name']
    assert_equal expected_change, project.versions.last.changeset['name']
  end

  # 'application' => Project
  test 'project end use returned on as part of paper trail on a application' do
    application = projects(:test_application)
    assert_difference 'PaperTrail::Version.count', 1 do
      application.end_uses << end_uses(:one)
    end

    assert_association_tracked(application, 'ProjectEndUse',
                               application.project_end_uses.first.id)
  end

  test 'project classification returned on as part of paper trail on a application' do
    application = projects(:test_application)
    assert_difference 'PaperTrail::Version.count', 1 do
      application.classifications << classifications(:one)
    end

    assert_association_tracked(application, 'ProjectClassification',
                               application.project_classifications.first.id)
  end

  private

  def assert_association_tracked(application, item_type, item_id)
    audits = PaperTrail::Version.where(item_type: item_type, item_id: item_id)
    assert_equal 1, audits.size
    assert_includes(find_all_versions(application), audits.first)
  end

  def find_all_versions(resource)
    item_type = resource.class.name
    item_id   = resource.id
    item_fk   = item_type.foreign_key

    PaperTrail::Version.where(<<~SQL, item_type: item_type, item_id: item_id, item_fk: item_fk)
      (item_type = :item_type and item_id = :item_id)
        or id in
          (select distinct version_id
           from version_associations
           where foreign_key_name = :item_fk and
           foreign_key_id = :item_id)
    SQL
  end
end
