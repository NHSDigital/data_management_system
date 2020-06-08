require 'test_helper'

module Pseudo
  class PpatientTest < ActiveSupport::TestCase
    test 'patient record (prescription type) created successfully' do
      assert_equal 4, Ppatient.count
    end

    test 'cannot create patient record with invalid subclass' do
      fields = pseudo_ppatients(:patient1).attributes.with_indifferent_access
      fields[:type] = 'clearly_nonexistent'
      assert_raises(ActiveRecord::SubclassNotFound) { Ppatient.new(fields) }
    end

    test 'blank patient record cannot be created' do
      # binding.pry
      pat = Ppatient.new
      refute pat.save
    end
  end
end
