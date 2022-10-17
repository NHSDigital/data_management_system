require 'test_helper'
# require 'import/genotype'
# require 'import/colorectal/core/genotype_mmr'
# require 'import/brca/core/provider_handler'
# require 'import/storage_manager/persister'
class ManchesterHandlerTest < ActiveSupport::TestCase
  def setup
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Brca::Providers::Manchester::ManchesterHandler.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
  end

  # TODO: DOSAGE RECORDS: records need CDNA_REGEX coding. Not seen in real data, but chances are !=0 for this to happen. Records are automatically assigned a normal status if an exonic variant is not found. Need to assess if real normal or possible fails. Normal might be assigned twice of the same gene.
  # TODO: NON-DOSAGE RECORDS: Shall we include in Full Screen tests also genes not listed in exons? That would be against Fiona's initial mapping rules
  # TODO: MLH1/MSH2 might be troublesome to recognise for regexes, even if mostly rescued by other exons

  test 'Targeted positive non dosage record gene in moltesttype' do
    @importer_stdout, @importer_stderr = capture_io do
      genotypes_exon_molttype_groups = [
        ['c.5350_5351delAA', 'c.5350_5351delAA', 'BRCA2 ex11RF/11UR', 'BRCA2 Predictive Test Report'],
        ['c.5350_5351delAA', 'c.5350_5351delAA', 'BRCA2 ex11RF/11UR', 'BRCA2 Predictive Test Report']
      ]

      record = build_raw_record(genotypes_exon_molttype_groups, 'pseudo_id1' => 'bob')
      genotype = Import::Brca::Core::GenotypeBrca.new(record)
      genotype.add_passthrough_fields(record.mapped_fields,
                                      record.raw_fields,
                                      Import::Helpers::Brca::Providers::R0a::R0aConstants::PASS_THROUGH_FIELDS_COLO)
      @handler.process_fields(record)
      @handler.testscope_from_rawfields(genotype, record)
      mutations = @handler.assign_gene_mutation(genotype, record)
      assert_equal 'Targeted BRCA mutation test', genotype.attribute_map['genetictestscope']
      assert mutations.one?
      assert_equal 'c.5350_5351del', mutations[0].attribute_map['codingdnasequencechange']
    end
  end

  test 'Targeted non dosage record no gene in moltesttype' do
    @importer_stdout, @importer_stderr = capture_io do
      genotypes_exon_molttype_groups = [
        ['Normal', nil, 'BRCA1_BRCA1', 'Rare Disease Service - Carrier Testing Report']
      ]

      record = build_raw_record(genotypes_exon_molttype_groups, 'pseudo_id1' => 'bob')
      genotype = Import::Brca::Core::GenotypeBrca.new(record)
      genotype.add_passthrough_fields(record.mapped_fields,
                                      record.raw_fields,
                                      Import::Helpers::Brca::Providers::R0a::R0aConstants::PASS_THROUGH_FIELDS_COLO)
      @handler.process_fields(record)
      @handler.testscope_from_rawfields(genotype, record)
      mutations = @handler.assign_gene_mutation(genotype, record)
      assert_equal 'Targeted BRCA mutation test', genotype.attribute_map['genetictestscope']
      assert mutations.one?
      assert_equal 1, mutations[0].attribute_map['teststatus']
    end
  end

  test 'Targeted non dosage record mutation analysis' do
    @importer_stdout, @importer_stderr = capture_io do
      genotypes_exon_molttype_groups = [
        ['Normal', '', 'BRCA1', 'BRCA1 Mutation Analysis Report'],
        ['Normal', '', 'BRCA1', 'BRCA1 Mutation Analysis Report']
      ]

      record = build_raw_record(genotypes_exon_molttype_groups, 'pseudo_id1' => 'bob')
      genotype = Import::Brca::Core::GenotypeBrca.new(record)
      genotype.add_passthrough_fields(record.mapped_fields,
                                      record.raw_fields,
                                      Import::Helpers::Brca::Providers::R0a::R0aConstants::PASS_THROUGH_FIELDS_COLO)
      @handler.process_fields(record)
      @handler.testscope_from_rawfields(genotype, record)
      mutations = @handler.assign_gene_mutation(genotype, record)
      assert_equal 'Targeted BRCA mutation test', genotype.attribute_map['genetictestscope']
      assert mutations.one?
      assert_equal 1, mutations[0].attribute_map['teststatus']
    end
  end

  test 'Targeted failed non dosage record' do
    @importer_stdout, @importer_stderr = capture_io do
      genotypes_exon_molttype_groups = [
        ['Fail', 'Fail', 'BRCA2 Ex10', 'PREDICTIVE TESTING REPORT'],
        ['Fail', 'Fail', 'BRCA1 Ex4a', 'PREDICTIVE TESTING REPORT'],
        ['Fail', 'Normal', 'ATM Ex4c', 'PREDICTIVE TESTING REPORT'],
        ['Fail', 'Fail', 'CHEK Ex2', 'PREDICTIVE TESTING REPORT']
      ]

      record = build_raw_record(genotypes_exon_molttype_groups, 'pseudo_id1' => 'bob')
      genotype = Import::Brca::Core::GenotypeBrca.new(record)
      genotype.add_passthrough_fields(record.mapped_fields,
                                      record.raw_fields,
                                      Import::Helpers::Brca::Providers::R0a::R0aConstants::PASS_THROUGH_FIELDS_COLO)
      @handler.process_fields(record)
      @handler.testscope_from_rawfields(genotype, record)
      assert_equal 'Targeted BRCA mutation test', genotype.attribute_map['genetictestscope']
      mutations = @handler.assign_gene_mutation(genotype, record)
      assert_equal 3, mutations.size
      assert_equal 9, mutations[0].attribute_map['teststatus']
      assert_equal 9, mutations[1].attribute_map['teststatus']
      assert_equal 1, mutations[2].attribute_map['teststatus']
    end
  end

  test 'Targeted test multiple variants' do
    @importer_stdout, @importer_stderr = capture_io do
      genotypes_exon_molttype_groups = [
        ['c.9976A>T p.(Lys3326Ter) HET', 'c.9976A>T p.(Lys3326Ter) HET"', 'BRCA2_Ex27', 'BRCA2 Mutation Confirmation'],
        ['c.6275_6276delTT', 'c.6275_6276delTT', 'BRCA2ex11_6275delTTFR', 'BRCA2 Mutation Confirmation'],
        ['+/c.6275_6276delTT', 'Fail', 'BRCA26275delTTF/R', 'BRCA2 Mutation Confirmation'],
        ['+/c.6275_6276delTT', '+/c.6275_6276delTT', 'BRCA26275delTTF/R', 'BRCA2 Mutation Confirmation']
      ]

      record = build_raw_record(genotypes_exon_molttype_groups, 'pseudo_id1' => 'bob')
      genotype = Import::Brca::Core::GenotypeBrca.new(record)
      genotype.add_passthrough_fields(record.mapped_fields,
                                      record.raw_fields,
                                      Import::Helpers::Brca::Providers::R0a::R0aConstants::PASS_THROUGH_FIELDS_COLO)
      @handler.process_fields(record)
      mutations = @handler.assign_gene_mutation(genotype, record)
      assert_equal 2, mutations.size
      @handler.testscope_from_rawfields(genotype, record)
      assert_equal 'Targeted BRCA mutation test', genotype.attribute_map['genetictestscope']
      assert_equal 2, mutations[0].attribute_map['teststatus']
      assert_equal 'c.9976A>T', mutations[0].attribute_map['codingdnasequencechange']
      assert_equal 'c.6275_6276del', mutations[1].attribute_map['codingdnasequencechange']
    end
  end

  test 'Full Screen test multiple variants' do
    @importer_stdout, @importer_stderr = capture_io do
      genotypes_exon_molttype_groups = [
        ['Normal', 'Normal', 'BRCA2 Ex5_6', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex3', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 Frag4', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 10A', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex27', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['c.1910-51G>T het', 'c.1910-51G>T het', 'BRCA2 ex11A', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 Ex8', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 10B', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['c.6100C>T het (p.Arg2034Cys)', 'c.6100C>T het (p.Arg2034Cys)', 'BRCA2 ex11F', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 Ex7', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', nil, 'BRCA1 MLPA', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 Ex21', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['c.6100C>T het (p.Arg2034Cys)', 'c.6100C>T het (p.Arg2034Cys)', 'BRCA2 11F', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA1 11E', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 Ex26', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 Ex15', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex18', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA1 11A', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex14', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex13', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA1 11C', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex12', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA1 11D', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 Ex16', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 Ex9', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA1 11B', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA1Ex7', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex17', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA1 Frag1', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex2', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA1 Frag2', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA1 Frag4', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA1 Frag5', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA1 Frag3', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 Ex4', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', nil, 'BRCA2 MLPA', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 Ex19', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['c.1910-51G>T het', 'c.1910-51G>T het', 'BRCA2 11A', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 11E', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 Ex20', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 11C', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 Ex25', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 11D', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA1 Frag6', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 11B', 'BRCA1/BRCA2 MUTATION ANALYSIS']
      ]

      record = build_raw_record(genotypes_exon_molttype_groups, 'pseudo_id1' => 'bob')
      genotype = Import::Brca::Core::GenotypeBrca.new(record)
      genotype.add_passthrough_fields(record.mapped_fields,
                                      record.raw_fields,
                                      Import::Helpers::Brca::Providers::R0a::R0aConstants::PASS_THROUGH_FIELDS_COLO)
      @handler.process_fields(record)
      mutations = @handler.assign_gene_mutation(genotype, record)
      assert_equal 3, mutations.size
      @handler.testscope_from_rawfields(genotype, record)
      assert_equal 'Full screen BRCA1 and BRCA2', genotype.attribute_map['genetictestscope']
      assert_equal 2, mutations[0].attribute_map['teststatus']
      assert_equal 2, mutations[1].attribute_map['teststatus']
      assert_equal 1, mutations[2].attribute_map['teststatus']
      assert_equal 'c.1910-51G>T', mutations[0].attribute_map['codingdnasequencechange']
      assert_equal 'c.6100C>T', mutations[1].attribute_map['codingdnasequencechange']
    end
  end

  test 'Full Screen overlapping variant' do
    @importer_stdout, @importer_stderr = capture_io do
      genotypes_exon_molttype_groups = [
        ['Normal', 'Normal', 'BRCA2 Frag 7', 'BRCA2 Mutation Analysis - BATCH @batch'],
        ['c.7006 C>T het (p.Arg2336Cys)', 'c.7006 C>T het (p.Arg2336Cys)', 'BRCA2 Frag 3', 'BRCA2 Mutation Analysis - BATCH @batch'],
        ['Normal', 'Normal', 'BRCA2 Frag 1', 'BRCA2 Mutation Analysis - BATCH @batch'],
        ['Normal', 'Normal', 'BRCA2_F6', 'BRCA2 Mutation Analysis - BATCH @batch'],
        ['Normal', 'Normal', 'BRCA2 Frag 4', 'BRCA2 Mutation Analysis - BATCH @batch'],
        ['Normal', 'Normal', 'BRCA2 ex10A', 'BRCA2 Mutation Analysis - BATCH @batch'],
        ['Normal', 'Normal', 'BRCA2 ex10A', 'BRCA2 Mutation Analysis - BATCH @batch'],
        ['Normal', 'Normal', 'BRCA2_F6', 'BRCA2 Mutation Analysis - BATCH @batch'],
        ['Normal', 'Normal', 'BRCA2_F6', 'BRCA2 Mutation Analysis - BATCH @batch'],
        ['Normal', 'Normal', 'BRCA2_F6', 'BRCA2 Mutation Analysis - BATCH @batch'],
        ['Normal', 'Normal', 'BRCA2_F6', 'BRCA2 Mutation Analysis - BATCH @batch'],
        ['c.7006 C>T (p.Arg2336Cys)', 'c.7006 C>T (p.Arg2336Cys)', 'BRCA2 MLPA', 'BRCA2 Mutation Analysis - BATCH @batch'],
        ['Normal', 'Normal', 'BRCA1 Ex11d', 'BRCA2 Mutation Analysis - BATCH @batch']
      ]

      record = build_raw_record(genotypes_exon_molttype_groups, 'pseudo_id1' => 'bob')
      genotype = Import::Brca::Core::GenotypeBrca.new(record)
      genotype.add_passthrough_fields(record.mapped_fields,
                                      record.raw_fields,
                                      Import::Helpers::Brca::Providers::R0a::R0aConstants::PASS_THROUGH_FIELDS_COLO)
      @handler.process_fields(record)
      @handler.testscope_from_rawfields(genotype, record)
      mutations = @handler.assign_gene_mutation(genotype, record)
      assert_equal 'Full screen BRCA1 and BRCA2', genotype.attribute_map['genetictestscope']
      assert_equal 'c.7006C>T', mutations[0].attribute_map['codingdnasequencechange']
      assert_equal 1, mutations[1].attribute_map['teststatus']
    end
  end

  test 'Full Screen single variant' do
    @importer_stdout, @importer_stderr = capture_io do
      genotypes_exon_molttype_groups = [
        ['c.1100delC', 'c.1100delC', '<Select>', 'BRCA1 & BRCA2/CHEK2 DOSAGE ANALYSIS'],
        ['c.1100delC', 'c.1100delC', 'Chek2', 'BRCA1 & BRCA2/CHEK2 DOSAGE ANALYSIS'],
        ['Normal Chek 2', nil, 'BRCA2 MLPA', 'BRCA1 & BRCA2/CHEK2 DOSAGE ANALYSIS'],
        ['c.1100delC', 'c.1100delC', '<Select>', 'BRCA1 & BRCA2/CHEK2 DOSAGE ANALYSIS'],
        ['Normal', nil, 'BRCA1 MLPA', 'BRCA1 & BRCA2/CHEK2 DOSAGE ANALYSIS'],
        ['Normal Chek2', nil, 'BRCA2 MLPA', 'BRCA1 & BRCA2/CHEK2 DOSAGE ANALYSIS'],
        ['c.1100delC', 'c.1100delC', '<Select>', 'BRCA1 & BRCA2/CHEK2 DOSAGE ANALYSIS'],
        ['c.1100delC', 'c.1100delC', '<Select>', 'BRCA1 & BRCA2/CHEK2 DOSAGE ANALYSIS']
      ]

      record = build_raw_record(genotypes_exon_molttype_groups, 'pseudo_id1' => 'bob')
      genotype = Import::Brca::Core::GenotypeBrca.new(record)
      genotype.add_passthrough_fields(record.mapped_fields,
                                      record.raw_fields,
                                      Import::Helpers::Brca::Providers::R0a::R0aConstants::PASS_THROUGH_FIELDS_COLO)
      @handler.process_fields(record)
      @handler.testscope_from_rawfields(genotype, record)
      mutations = @handler.assign_gene_mutation(genotype, record)
      assert_equal 'Full screen BRCA1 and BRCA2', genotype.attribute_map['genetictestscope']
      assert_equal 'c.1100del', mutations[0].attribute_map['codingdnasequencechange']
      assert_equal 1, mutations[1].attribute_map['teststatus']
    end
  end

  test 'Full Screen multiple variants from malformed record' do
    @importer_stdout, @importer_stderr = capture_io do
      genotypes_exon_molttype_groups = [
        ['Normal', 'Normal', 'BRCA2 ex10B', 'BRCA2 DOSAGE ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2_11d', 'BRCA2 DOSAGE ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex11A', 'BRCA2 DOSAGE ANALYSIS'],
        ['c.1257 A>G (p.Tyr42Cys)', 'c.1257 A>G (p.Tyr42Cys)', 'BRCA2 Frag 7', 'BRCA2 DOSAGE ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex11E', 'BRCA2 DOSAGE ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 Frag 2', 'BRCA2 DOSAGE ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 Frag 1', 'BRCA2 DOSAGE ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 Frag 3', 'BRCA2 DOSAGE ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex11F', 'BRCA2 DOSAGE ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 Frag 5', 'BRCA2 DOSAGE ANALYSIS'],
        ['c.10110 G>A het (p.Arg3370Arg)', 'c.10110 G>A het (p.Arg3370Arg)', 'BRCA1 ex27', 'BRCA2 DOSAGE ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 Frag 1', 'BRCA2 DOSAGE ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex10A', 'BRCA2 DOSAGE ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 Frag 6', 'BRCA2 DOSAGE ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex11C', 'BRCA2 DOSAGE ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 Frag 3', 'BRCA2 DOSAGE ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex11B', 'BRCA2 DOSAGE ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 Frag 4', 'BRCA2 DOSAGE ANALYSIS'],
        ['Normal', nil, 'BRCA2 MLPA', 'BRCA2 DOSAGE ANALYSIS']
      ]

      record = build_raw_record(genotypes_exon_molttype_groups, 'pseudo_id1' => 'bob')
      genotype = Import::Brca::Core::GenotypeBrca.new(record)
      genotype.add_passthrough_fields(record.mapped_fields,
                                      record.raw_fields,
                                      Import::Helpers::Brca::Providers::R0a::R0aConstants::PASS_THROUGH_FIELDS_COLO)
      @handler.process_fields(record)
      @handler.testscope_from_rawfields(genotype, record)
      mutations = @handler.assign_gene_mutation(genotype, record)
      assert_equal 'Full screen BRCA1 and BRCA2', genotype.attribute_map['genetictestscope']
      assert_equal 8, mutations.uniq[0].attribute_map['gene']
      assert_equal 7, mutations.uniq[1].attribute_map['gene']
      assert_equal 'c.1257A>G', mutations.uniq[0].attribute_map['codingdnasequencechange']
      assert_equal 'c.10110G>A', mutations.uniq[1].attribute_map['codingdnasequencechange']
      assert_equal 2, mutations.uniq.size
      assert_equal 2, mutations.uniq[0].attribute_map['teststatus']
      assert_equal 2, mutations.uniq[1].attribute_map['teststatus']
    end
  end

  test 'Exonic variants in dosage or non dosage test' do
    @importer_stdout, @importer_stderr = capture_io do
      genotypes_exon_molttype_groups = [
        ['Normal', 'Normal', 'BRCA2 ex26', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex11F', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA1 Frag6', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex11E', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['ex13dup', nil, '<Select>', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA1 11D', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex15', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex11C', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex18', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA1 Frag5', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex14', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex11B', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex11A', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA1 11E', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 Frag4', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex3', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['ex13 dup', nil, 'BRCA1B', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex11D', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['ex13dup', nil, 'BRCA1', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', nil, 'BRCA2 MLPA', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['ex13dup', nil, 'BRCA1', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA1 11A', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex10B', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex16', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex13', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA1 11C', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex10A', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex25', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA1 11B', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex27', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA1 Ex7', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex20', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA1 Frag1', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex21', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex7', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex2', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex4', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA1 Frag2', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex5_6', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex8', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA1 Frag4', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex9', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA1 Frag3', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex19', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex17', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['Normal', 'Normal', 'BRCA2 ex12', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['BRCA1 ex 13 duplication', nil, 'BRCA1 MLPA', 'BRCA1/BRCA2 MUTATION ANALYSIS'],
        ['BRCA1 ex 13 duplication', nil, 'BRCA1 MLPA', 'BRCA1/BRCA2 MUTATION ANALYSIS']
      ]

      record = build_raw_record(genotypes_exon_molttype_groups, 'pseudo_id1' => 'bob')
      genotype = Import::Brca::Core::GenotypeBrca.new(record)
      genotype.add_passthrough_fields(record.mapped_fields,
                                      record.raw_fields,
                                      Import::Helpers::Brca::Providers::R0a::R0aConstants::PASS_THROUGH_FIELDS_COLO)
      @handler.process_fields(record)
      @handler.testscope_from_rawfields(genotype, record)
      mutations = @handler.assign_gene_mutation(genotype, record)
      assert_equal 'Full screen BRCA1 and BRCA2', genotype.attribute_map['genetictestscope']
      assert_equal 8, mutations[0].attribute_map['gene']
      assert_equal 7, mutations[1].attribute_map['gene']
      assert_equal 2, mutations.size
      assert_equal 1, mutations[0].attribute_map['teststatus']
      assert_equal 2, mutations[1].attribute_map['teststatus']
    end
  end

  test 'Normal Exonic variants in dosage tests' do
    @importer_stdout, @importer_stderr = capture_io do
      genotypes_exon_molttype_groups = [
        ['No evidence of familial deletion', nil, 'BRCA2 MLPA', 'BRCA2 DOSAGE ANALYSIS - PREDICTIVE TESTING REPORT']
      ]

      record = build_raw_record(genotypes_exon_molttype_groups, 'pseudo_id1' => 'bob')
      genotype = Import::Brca::Core::GenotypeBrca.new(record)
      genotype.add_passthrough_fields(record.mapped_fields,
                                      record.raw_fields,
                                      Import::Helpers::Brca::Providers::R0a::R0aConstants::PASS_THROUGH_FIELDS_COLO)
      @handler.process_fields(record)
      @handler.testscope_from_rawfields(genotype, record)
      mutations = @handler.assign_gene_mutation(genotype, record)
      assert_equal 'Targeted BRCA mutation test', genotype.attribute_map['genetictestscope']
      assert mutations.one?
      assert_equal 8, mutations[0].attribute_map['gene']
      assert_equal 1, mutations[0].attribute_map['teststatus']
    end
  end

  test 'Dosage record positive result' do
    @importer_stdout, @importer_stderr = capture_io do
      genotypes_exon_molttype_groups = [
        ['c.1100delC', 'c.1100delC', '<Select>', 'BRCA1 & BRCA2/CHEK2 DOSAGE ANALYSIS'],
        ['c.1100delC', 'c.1100delC', 'Chek2', 'BRCA1 & BRCA2/CHEK2 DOSAGE ANALYSIS'],
        ['Normal', nil, 'BRCA2 MLPA', 'BRCA1 & BRCA2/CHEK2 DOSAGE ANALYSIS'],
        ['c.1100delC', 'c.1100delC', '<Select>', 'BRCA1 & BRCA2/CHEK2 DOSAGE ANALYSIS'],
        ['Normal', nil, 'BRCA1 MLPA', 'BRCA1 & BRCA2/CHEK2 DOSAGE ANALYSIS'],
        ['Normal', nil, 'BRCA2 MLPA', 'BRCA1 & BRCA2/CHEK2 DOSAGE ANALYSIS'],
        ['c.1100delC', 'c.1100delC', '<Select>', 'BRCA1 & BRCA2/CHEK2 DOSAGE ANALYSIS'],
        ['c.1100delC', 'c.1100delC', '<Select>', 'BRCA1 & BRCA2/CHEK2 DOSAGE ANALYSIS']
      ]
      record = build_raw_record(genotypes_exon_molttype_groups, 'pseudo_id1' => 'bob')
      genotype = Import::Brca::Core::GenotypeBrca.new(record)
      genotype.add_passthrough_fields(record.mapped_fields,
                                      record.raw_fields,
                                      Import::Helpers::Brca::Providers::R0a::R0aConstants::PASS_THROUGH_FIELDS_COLO)
      @handler.process_fields(record)
      mutations = @handler.assign_gene_mutation(genotype, record)
      @handler.testscope_from_rawfields(genotype, record)
      assert_equal 'Full screen BRCA1 and BRCA2', genotype.attribute_map['genetictestscope']
      assert_not mutations.one?
      assert_equal 2, mutations[0].attribute_map['teststatus']
      assert_equal 3, mutations.size
    end
  end

  test 'Dosage record positive result with false positive' do
    @importer_stdout, @importer_stderr = capture_io do
      genotypes_exon_molttype_groups = [
        ['c.1100delC', 'c.1100delC', '<Select>', 'BRCA1 & BRCA2/CHEK2 DOSAGE ANALYSIS'],
        ['c.1100delC', 'c.1100delC', 'Chek2', 'BRCA1 & BRCA2/CHEK2 DOSAGE ANALYSIS'],
        ['Normal Chek 2', nil, 'BRCA2 MLPA', 'BRCA1 & BRCA2/CHEK2 DOSAGE ANALYSIS'],
        ['c.1100delC', 'c.1100delC', '<Select>', 'BRCA1 & BRCA2/CHEK2 DOSAGE ANALYSIS'],
        ['Normal', nil, 'BRCA1 MLPA', 'BRCA1 & BRCA2/CHEK2 DOSAGE ANALYSIS'],
        ['Normal Chek2', nil, 'BRCA2 MLPA', 'BRCA1 & BRCA2/CHEK2 DOSAGE ANALYSIS'],
        ['c.1100delC', 'c.1100delC', '<Select>', 'BRCA1 & BRCA2/CHEK2 DOSAGE ANALYSIS'],
        ['c.1100delC', 'c.1100delC', '<Select>', 'BRCA1 & BRCA2/CHEK2 DOSAGE ANALYSIS']
      ]
      record = build_raw_record(genotypes_exon_molttype_groups, 'pseudo_id1' => 'bob')
      genotype = Import::Brca::Core::GenotypeBrca.new(record)
      genotype.add_passthrough_fields(record.mapped_fields,
                                      record.raw_fields,
                                      Import::Helpers::Brca::Providers::R0a::R0aConstants::PASS_THROUGH_FIELDS_COLO)
      @handler.process_fields(record)
      mutations = @handler.assign_gene_mutation(genotype, record)
      @handler.testscope_from_rawfields(genotype, record)
      assert_equal 'Full screen BRCA1 and BRCA2', genotype.attribute_map['genetictestscope']
      assert_not mutations.one?
      assert_equal 2, mutations.size
      assert_equal 2, mutations[0].attribute_map['teststatus']
    end
  end

  test 'Dosage record negative result' do
    # Dosage records are parsed only for large exonic variants, and no CDNA_REGEX condition was
    # formulated for them. As expected, this fires up as a negative record.
    # Might think about a DEBUG logger message about it.
    @importer_stdout, @importer_stderr = capture_io do
      genotypes_exon_molttype_groups = [
        ['Normal', '', 'BRCA2_MLPA', 'BRCA1 & BRCA2 DOSAGE ANALYSIS'],
        ['Normal', '', 'BRCA2_MLPA', 'BRCA1 & BRCA2 DOSAGE ANALYSIS'],
        ['Normal', '', 'BRCA1_MLPA', 'BRCA1 & BRCA2 DOSAGE ANALYSIS'],
        ['Normal', '', 'BRCA1_MLPA', 'BRCA1 & BRCA2 DOSAGE ANALYSIS']
      ]
      record = build_raw_record(genotypes_exon_molttype_groups, 'pseudo_id1' => 'bob')
      genotype = Import::Brca::Core::GenotypeBrca.new(record)
      genotype.add_passthrough_fields(record.mapped_fields,
                                      record.raw_fields,
                                      Import::Helpers::Brca::Providers::R0a::R0aConstants::PASS_THROUGH_FIELDS_COLO)
      @handler.process_fields(record)
      @handler.testscope_from_rawfields(genotype, record)
      mutations = @handler.assign_gene_mutation(genotype, record)
      assert_equal 'Full screen BRCA1 and BRCA2', genotype.attribute_map['genetictestscope']
      assert_not mutations.one?
      assert_equal 1, mutations[0].attribute_map['teststatus']
      assert_equal 1, mutations[1].attribute_map['teststatus']
    end
  end

  test 'no genetictestscope' do
    @importer_stdout, @importer_stderr = capture_io do
      genotypes_exon_molttype_groups = [
        ['c.5319G>C p.(Glu1773Asp)', 'c.5319G>C p.(Glu1773Asp)', 'BRCA2ex11Eint', 'BRCA 1 Unclassified Variant Loss of Heterozygosity Studies from Archive Material']
      ]
      record = build_raw_record(genotypes_exon_molttype_groups, 'pseudo_id1' => 'bob')
      genotype = Import::Brca::Core::GenotypeBrca.new(record)
      genotype.add_passthrough_fields(record.mapped_fields,
                                      record.raw_fields,
                                      Import::Helpers::Brca::Providers::R0a::R0aConstants::PASS_THROUGH_FIELDS_COLO)
      @handler.process_fields(record)
      @handler.testscope_from_rawfields(genotype, record)
      assert_equal 'Unable to assign BRCA genetictestscope', genotype.attribute_map['genetictestscope']
    end
  end

  private

  def build_raw_record(genotypes_exon_molttype_groups, options = {})
    default_options = { 'pseudo_id1' => '',
                        'pseudo_id2' => '',
                        'encrypted_demog' => '',
                        'clinical.to_json' => clinical_json,
                        'encrypted_rawtext_demog' => '',
                        'rawtext_clinical.to_json' => rawtext_clinical_json(genotypes_exon_molttype_groups) }
    Import::Germline::RawRecord.new(default_options.merge!(options))
  end

  def clinical_json
    { consultantcode: 'Consultant Code',
      receiveddate: '2005-12-09T00:00:00.000+00:00',
      authoriseddate: '2012-11-12T00:00:00.000+00:00',
      sortdate: '2005-12-09T00:00:00.000+00:00',
      genetictestscope: 'GENETIC TEST SCOPE',
      genotype: 'Genotype' }.to_json
  end

  def default_rawtext_clinical_hash
    { sex: '1',
      consultantname: 'Consultant Name',
      providercode: '',
      servicereportidentifier: '000000',
      urgency: '2',
      receiveddate: '2005-12-09 00:00:00',
      authoriseddate: '2012-11-12 00:00:00',
      source: 'Manchester',
      genotypes: '11',
      wlus: '1300',
      genus: '',
      quality1: '1',
      quality2: '1',
      withdrawn: 'false',
      discode: '45',
      genocomm: 'None',
      disease: 'BRCA' }
  end

  def rawtext_clinical_json(genotypes_exon_molttype_groups)
    raw_json = []
    genotypes_exon_molttype_groups.each do |genotypes_exon_molttype_group|
      hash = default_rawtext_clinical_hash
      hash[:genotype] = genotypes_exon_molttype_group[0]
      hash[:genotype2] = genotypes_exon_molttype_group[1]
      hash[:exon] = genotypes_exon_molttype_group[2]
      hash[:moleculartestingtype] = genotypes_exon_molttype_group[3]
      raw_json << hash
    end
    raw_json.to_json
  end
end
