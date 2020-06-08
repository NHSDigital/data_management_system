require 'test_helper'

module Pseudo
  class PrescriptionDataTest < ActiveSupport::TestCase
    test 'prescription data records created successfully' do
      assert_equal 2, PrescriptionData.count
    end

    test 'blank prescription data record cannot be created' do
      # needs pseudoid - see app/models/prescription_data.rb
      pat1 = Ppatient.find_by(type: 'Pseudo::Prescription')
      fields = { prescription_dataid: nil, pat_age: nil }
      pr = pat1.prescription_data.new(fields)
      refute pr.save
    end
  end
end
