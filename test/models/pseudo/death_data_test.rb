require 'test_helper'

module Pseudo
  class DeathDataTest < ActiveSupport::TestCase
    test 'exactly one death data record created successfully' do
      # ppatient has_one death_data
      assert_equal 1, DeathData.count
    end

    test 'blank death data record cannot be created' do
      # needs pseudoid - see app/models/death_data.rb
      DeathData.delete_all
      fields = { death_dataid: nil, ppatient_id: nil }
      dd = DeathData.new(fields)
      refute dd.save
    end
  end
end
