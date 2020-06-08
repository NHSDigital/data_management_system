require 'test_helper'

module Pseudo
  class BirthDataTest < ActiveSupport::TestCase
    test 'exactly one birth data record created successfully' do
      # ppatient has_one birth_data
      assert_equal 1, BirthData.count
    end

    test 'blank birth data record cannot be created' do
      # needs pseudoid - see app/models/birth_data.rb
      BirthData.delete_all
      fields = { birth_dataid: nil, ppatient_id: nil }
      bd = BirthData.new(fields)
      refute bd.save
    end
  end
end
