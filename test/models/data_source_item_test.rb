require 'test_helper'

class DataSourceItemTest < ActiveSupport::TestCase
  test 'should only allow unique data item names per data source' do
    data_source_item = DataSourceItem.new(name: 'dateofbirth',
                                          data_source: data_sources(:births_gold))
    refute data_source_item.valid?, 'Should be invlaid -  Name already in use'
    assert data_source_item.errors[:name].any?, 'Should have errors - Name already in use'
    expected_error = 'Name already in use for this data source'
    assert data_source_item.errors.full_messages.include? expected_error
  end

  test 'should flag data item as in use' do
    skip
    # data item in use in projects(:one)
    data_item_in_use = data_source_items(:birth_gold_dob)
    assert data_item_in_use.in_use?

    # data item not in use
    data_item = data_source_items(:birth_transaction_dob)
    refute data_item.in_use?
  end

  test 'should not destroy data items in use' do
    skip
    # data item in use in projects(:one)
    data_item_in_use = data_source_items(:birth_gold_dob)
    refute data_item_in_use.destroy

    # data item not in use
    data_item = data_source_items(:birth_transaction_dob)
    assert data_item.destroy
  end

  test 'should be invalid without governance' do
    data_source_item = DataSourceItem.new(name: 'test name', description: 'a description',
                                          data_source: data_sources(:births_gold))
    refute data_source_item.valid?, 'should be invalid - governance is blank'
    assert data_source_item.errors[:governance].any?, 'should have an error - governance is blank'
  end

  test 'should be invalid without a name' do
    data_source_item = DataSourceItem.new(description: 'a description',
                                          governance: 'DIRECT IDENTIFIER',
                                          data_source: data_sources(:births_gold))
    refute data_source_item.valid?, 'should be invalid - name blank'
    assert data_source_item.errors[:name].any?, 'should have an error - name blank'
  end

  test 'should be invalid without a description' do
    data_source_item = DataSourceItem.new(name: 'test name', governance: 'DIRECT IDENTIFIER',
                                          data_source: data_sources(:births_gold))
    refute data_source_item.valid?, 'should be invalid - description blank'
    assert data_source_item.errors[:description].any?, 'should have an error - description blank'
  end
end
