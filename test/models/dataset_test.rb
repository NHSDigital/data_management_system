require 'test_helper'
class DatasetTest < ActiveSupport::TestCase
  test 'name uniqueness' do
    Dataset.create!(name: 'Uniqueness Test', dataset_type: dataset_type(:table_spec),
                    team: Team.first)
    new_dataset = Dataset.new(name: 'Uniqueness Test')
    refute new_dataset.valid?
    assert_includes new_dataset.errors.details[:dataset_type], error: :blank
    new_dataset.dataset_type = dataset_type(:table_spec)
    new_dataset.team = Team.first
    refute new_dataset.valid?
    assert_includes new_dataset.errors.details[:name], error: :taken, value: 'Uniqueness Test'
  end

  test 'should save schema pack to zip' do
    dataset =  Dataset.find_by(name: 'COSD')
    dataset_version = dataset.dataset_versions.find_by(semver_version: '8.2')
    Dataset.any_instance.stubs(:zip_file_path).returns(Rails.root.join('tmp'))
    SchemaPack.new(dataset_version)
    created_zip = Rails.root.join('tmp', 'COSD_v8-2.zip')
    assert File.exist?(created_zip)

    contents = Zip::File.open(created_zip) do |zip_file|
      zip_file.map(&:name)
    end

    expected_contents =
      %w[sample_xml/COSD-v8-2_sample_choices.xml sample_xml/COSD-v8-2_sample_items.xml
         schema/COSD-v8-2.xsd schema/COSD-v8-2_BREAST.xsd
         schema/COSD-v8-2_CNS.xsd schema/COSD-v8-2_COLORECTAL.xsd schema/COSD-v8-2_CTYA.xsd
         schema/COSD-v8-2_DATA_TYPES.xsd schema/COSD-v8-2_DEMOGRAPHICS.xsd
         schema/COSD-v8-2_GYNAECOLOGICAL.xsd schema/COSD-v8-2_HAEMATOLOGICAL.xsd
         schema/COSD-v8-2_HEADNECK.xsd schema/COSD-v8-2_IMAGING.xsd
         schema/COSD-v8-2_LINKAGEDIAGNOSTICDETAILS.xsd schema/COSD-v8-2_LINKAGEPATIENTID.xsd
         schema/COSD-v8-2_LIVER.xsd schema/COSD-v8-2_LUNG.xsd
         schema/COSD-v8-2_SARCOMA.xsd schema/COSD-v8-2_SKIN.xsd schema/COSD-v8-2_TREATMENT.xsd
         schema/COSD-v8-2_UPPERGI.xsd schema/COSD-v8-2_UROLOGICAL.xsd]

    # Schema contents present. Additional Schema browser content will also be in zip
    assert contents.sort & expected_contents == expected_contents, 'unexpected Zip file contents'
    # clean up
    system("rm #{created_zip}")
    refute File.exist?(created_zip)
  end

  test 'returns approvers for dataset if present' do
    dataset = Dataset.find_by(name: 'COSD')
    user = users(:standard_user_one_team)
    Grant.create(dataset: dataset, roleable: DatasetRole.fetch(:approver), user: user).tap(&:save)
    Grant.create(dataset: dataset, roleable: DatasetRole.find_by(name: 'Not Approver'), user: users(:standard_user2)).tap(&:save)

    assert_equal 1, dataset.approvers.count
    assert_equal user, dataset.approvers.first
  end
end
