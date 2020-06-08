require 'test_helper'

class DivisionTest < ActiveSupport::TestCase
  test 'blank division cannot be saved' do
    division = Division.new
    division.directorate = directorates(:one)
    refute division.save
    division.name = 'Test team name'
    assert division.save
  end

  test 'duplicate division name cannot be saved in same directorate' do
    division = Division.new
    division.directorate = directorates(:one)
    division.name = 'Test team name'
    assert division.save
    division2 = Division.new
    division2.directorate = directorates(:one)
    division2.name = 'Test team name'
    refute division2.save
  end

  test 'validate name and head of profession call' do
    division = Division.new
    division.directorate = directorates(:one)
    division.name = 'Test team'
    division.head_of_profession = 'Ned Ryerson'
    assert_equal division.name_and_head, 'Test team, Ned Ryerson(0)'
  end

  test 'validate only active divsions returned by default' do
    assert_equal Division.count, 4
    division = Division.new
    division.directorate = directorates(:one)
    division.name = 'Test team'
    division.head_of_profession = 'Ned Ryerson'
    division.active = false
    division.save
    assert_equal Division.count + 1 , Division.unscoped.count
  end

end
