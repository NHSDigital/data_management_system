require 'test_helper'

module Pseudo
  class MolecularDataTest < ActiveSupport::TestCase
    test 'exactly one molecular data record created successfully' do
      # ppatient has_one molecular_data
      assert_equal 1, MolecularData.count
    end

    test 'blank molecular data record cannot be created' do
      # needs pseudoid - see app/models/molecular_data.rb
      MolecularData.delete_all
      fields = { molecular_dataid: nil, ppatient_id: nil }
      md = MolecularData.new(fields)
      refute md.save
    end

    test 'molecular data should support genetic_test_results structure' do
      md = MolecularData.new(ppatient: Ppatient.first)
      md.save!
      assert md.valid?, "should be valid:\n#{md.errors.inspect}"
      gtr1 = Pseudo::GeneticTestResult.create(molecular_data: md,
                                              report: 'We sequenced a sample.')
      assert gtr1.valid?, "should be valid:\n#{gtr1.errors.inspect}"
      gtr2 = Pseudo::GeneticTestResult.create(molecular_data: md,
                                              report: 'We sequenced another sample.')
      gsv2a = Pseudo::GeneticSequenceVariant.create(genetic_test_result: gtr2,
                                                    genomicchange: 'No change')
      gsv2b = Pseudo::GeneticSequenceVariant.create(genetic_test_result: gtr2,
                                                    'genomicchange': 'XYZ')
      assert gtr2.valid?, "should be valid:\n#{gtr2.errors.inspect}"
      assert gsv2a.valid?, "should be valid:\n#{gsv2a.errors.inspect}"
      assert gsv2b.valid?, "should be valid:\n#{gsv2b.errors.inspect}"
      assert md.valid?, "should be valid:\n#{md.errors.inspect}"
      # Ensure structure preserved over save and reload
      md2 = MolecularData.find(md.id)
      assert_equal Set.new([gtr1, gtr2]),
                   Set.new(Pseudo::GeneticTestResult.where(molecular_data: md2).to_a)
    end

    # Old JSONB structure test, superceded by first-class Pseudo::GeneticTestResult tables
    # test 'molecular data should enforce genetictestresults structure' do
    #   md = MolecularData.new(ppatient: Ppatient.first)
    #   assert_equal [], md.genetictestresults
    #   assert md.valid?, "should be valid:\n#{md.errors.inspect}"
    #   md.genetictestresults = '[]'
    #   refute md.valid?, "should be invalid:\n#{md.errors.inspect}"
    #   gtr1 = { 'report' => 'We sequenced a sample.' }
    #   gsv2a = { 'genomichange' => 'No change' }
    #   gsv2b = { 'genomichange' => 'XYZ' }
    #   gtr2 = { 'report' => 'We sequenced another sample.',
    #            'geneticsequencevariants' => [gsv2a, gsv2b] }
    #   md.genetictestresults = [gtr1, gtr2]
    #   assert md.valid?, "should be valid:\n#{md.errors.inspect}"
    #   # Ensure JSON preserved over save and reload
    #   md.save!
    #   md2 = MolecularData.find(md.id)
    #   assert_equal [gtr1, gtr2], md2.genetictestresults
    # end
  end
end
