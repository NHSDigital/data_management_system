require 'test_helper'
module Nodes
  class DatasetVersionLookupTest < ActiveSupport::TestCase
    test 'item_type' do
      assert_equal 'Imaging',
                   Nodes::DatasetVersionLookup.lookup(cosd_v_one, :type_name, 'Imaging', 'Breast')
      assert_equal 'CNSImaging',
                   Nodes::DatasetVersionLookup.lookup(cosd_v_one, :type_name, 'Imaging', 'CNS')
    end

    test 'node is common' do
      assert Nodes::DatasetVersionLookup.common?(cosd_v_one, 'LinkagePatientId', 'CNS')
      refute Nodes::DatasetVersionLookup.common?(cosd_v_one, 'Imaging', 'CNS')
    end

    test 'entity for category' do
      assert Nodes::DatasetVersionLookup.entity_for_category?(cosd_v_one, 'CNS', 'ImagingCNS')
      refute Nodes::DatasetVersionLookup.entity_for_category?(cosd_v_one, 'Breast', 'ImagingCNS')
    end

    private

    def cosd_v_one
      dataset = Dataset.find_by(name: 'COSD')
      DatasetVersion.find_by(semver_version: '9.0', dataset_id: dataset.id)
    end
  end
end
