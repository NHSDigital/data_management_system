require 'test_helper'
module Nodes
  class ChoiceTest < ActiveSupport::TestCase
    test 'optional_unbounded choice occurrences' do
      choice_node = new_choice_node('min_choice_test')
      choice_node.choice_type = ChoiceType.find_by(name: 'optional_unbounded')
      assert_changes 'choice_node.min_occurs', from: nil, to: 0 do
        assert_no_changes 'choice_node.max_occurs' do
          choice_node.save!
        end
      end
    end

    test 'optional_or choice occurrences' do
      choice_node = new_choice_node('min_choice_test')
      choice_node.choice_type = ChoiceType.find_by(name: 'optional_or')
      assert_changes 'choice_node.min_occurs', from: nil, to: 0 do
        assert_changes 'choice_node.max_occurs', from: nil, to: 1 do
          choice_node.save!
        end
      end
    end

    test 'optional_and_or choice occurrences' do
      choice_node = new_choice_node('min_choice_test')
      choice_node.choice_type = ChoiceType.find_by(name: 'optional_and_or')
      assert_changes 'choice_node.min_occurs', from: nil, to: 0 do
        assert_changes 'choice_node.max_occurs', from: nil, to: 2 do
          choice_node.save!
        end
      end
    end

    test 'mandatory_or choice occurrences' do
      choice_node = new_choice_node('min_choice_test')
      choice_node.choice_type = ChoiceType.find_by(name: 'mandatory_or')
      choice_node.min_occurs = 1
      assert_no_changes 'choice_node.min_occurs' do
        assert_changes 'choice_node.max_occurs', from: nil, to: 1 do
          choice_node.save!
        end
      end
    end

    test 'mandatory_and_or choice occurrences' do
      choice_node = new_choice_node('min_choice_test')
      choice_node.choice_type = ChoiceType.find_by(name: 'mandatory_and_or')
      choice_node.min_occurs = 1
      assert_no_changes 'choice_node.min_occurs' do
        assert_changes 'choice_node.max_occurs', from: nil, to: 2 do
          choice_node.save!
        end
      end
    end

    test 'mandatory_unbounded choice occurrences' do
      choice_node = new_choice_node('min_choice_test')
      choice_node.choice_type = ChoiceType.find_by(name: 'mandatory_unbounded')
      choice_node.min_occurs = 1
      assert_no_changes 'choice_node.min_occurs' do
        assert_no_changes 'choice_node.max_occurs' do
          choice_node.save!
        end
      end
    end

    # e.g must pick 2 choices only from 4
    test 'mandatory_multiple_or choice occurrences' do
      choice_node = new_choice_node('min_choice_test')
      choice_node.choice_type = ChoiceType.find_by(name: 'mandatory_multiple_or')
      choice_node.child_nodes =
        choice_node.child_nodes + %w[choice_three choice_four].map { |n| choice_item(n) }
      choice_node.min_occurs = 2
      assert_no_changes 'choice_node.min_occurs' do
        assert_changes 'choice_node.max_occurs', from: nil, to: 2 do
          choice_node.save!
        end
      end
    end

    test 'mandatory_multiple_and_or choice occurrences' do
      choice_node = new_choice_node('min_choice_test')
      choice_node.choice_type = ChoiceType.find_by(name: 'mandatory_multiple_and_or')
      choice_node.child_nodes =
        choice_node.child_nodes + %w[choice_three choice_four].map { |n| choice_item(n) }
      choice_node.min_occurs = 3
      assert_no_changes 'choice_node.min_occurs' do
        assert_changes 'choice_node.max_occurs', from: nil, to: 4 do
          choice_node.save!
        end
      end
    end

    test 'choice must have a choice_type' do
      choice_node = Nodes::Choice.new(name: 'NewChoice')
      refute choice_node.valid?
      assert choice_node.errors.messages.keys.include? :choice_type
    end

    test 'min_occurs_required_for_choice_type' do
      choice_node = new_choice_node('min_choice_test')
      choice_node.choice_type = ChoiceType.find_by(name: 'mandatory_multiple_or')
      error_msg = 'Minimum occurrences must be defined if multiple mandatory options are allowed'
      refute choice_node.valid?(:publish)
      assert choice_node.errors.messages[:choice].include? error_msg
      choice_node.choice_type = ChoiceType.find_by(name: 'mandatory_multiple_and_or')
      refute choice_node.valid?(:publish)
      assert choice_node.errors.messages[:choice].include? error_msg
      choice_node.child_nodes << choice_item('choice_three')
      choice_node.min_occurs = 2
      assert choice_node.valid?
    end

    test 'choice_must_have_child_nodes' do
      choice_node = Nodes::Choice.new(name: 'NewChoice')
      refute choice_node.valid?(:publish)
      error_msg = 'Choice must have some choices!'
      assert choice_node.errors.messages[:choice].include? error_msg
    end

    test 'only_one_choice_available' do
      choice_node = Nodes::Choice.new(name: 'NewChoice')
      choice_node.child_nodes = [choice_item('choice_one')]
      refute choice_node.valid?(:publish)
      error_msg = 'Only one choice available for choice'
      assert choice_node.errors.messages[:choice].include? error_msg
    end

    test 'mandatory_choice_combinations' do
      choice_node = new_choice_node('mandatory_choice_combinations')
      choice_node.choice_type = ChoiceType.find_by(name: 'mandatory_multiple_or')
      choice_node.min_occurs = 1
      choice_node.save!
      choice_node.reload
      actual = choice_node.mandatory_choice_combinations.sort
      expected = choice_node.child_nodes.map { |i| [i] }.sort
      assert_equal  expected, actual, 'choice combinations not expected'
    end

    test 'valid_choice_combinations_optional' do
      choice_node = new_choice_node('valid_choice_combinations_optional')
      choice_node.choice_type = ChoiceType.find_by(name: 'optional_and_or')
      choice_node.min_occurs = 0
      choice_node.save!
      choice_node.reload
      actual = choice_node.valid_choice_combinations.sort
      expected = choice_node.child_nodes.map { |i| [i] }
      expected << []
      assert_equal expected.sort, actual, 'choice combinations not expected'
    end

    test 'valid_choice_combinations_mandatoary' do
      choice_node = new_choice_node('valid_choice_combinations_mandatoary')
      choice_node.choice_type = ChoiceType.find_by(name: 'mandatory_or')
      choice_node.min_occurs = 1
      choice_node.save!
      choice_node.reload
      actual = choice_node.valid_choice_combinations.sort
      expected = choice_node.child_nodes.sort
      assert_equal expected.sort, actual, 'choice combinations not expected'
    end

    private

    def new_choice_node(name)
      choice_node = Nodes::Choice.new(name: name)
      choice_node.child_nodes = %w[choice_one choice_two].map { |n| choice_item(n) }
      choice_node
    end

    def choice_item(name)
      Nodes::DataItem.new(name: name, min_occurs: 0, max_occurs: 1,
                          xml_type: date_xml_type, description: name + 'description')
    end

    def date_xml_type
      XmlType.find_by(name: 'ST_PHE_Date')
    end

    def dataset_version
      DatasetVersion.find_by(semver_version: '8.2', dataset_id: Dataset.find_by(name: 'COSD').id)
    end

    def treatment_choice
      @treatment_choice ||= Nodes::Choice.find_by(name: 'TreatmentChoice',
                                                  dataset_version: dataset_version)
    end

    def cns_code_item
      @cns_code_item ||= Nodes::DataItem.find_by(name: 'MadeUpCNSSpecificCodedChoiceItem',
                                                 dataset_version: dataset_version)
    end
  end
end
