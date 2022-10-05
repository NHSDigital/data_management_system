require 'test_helper'
#require 'import/genotype'
#require 'import/colorectal/core/genotype_mmr'
#require 'import/brca/core/provider_handler'
#require 'import/storage_manager/persister'
class ManchesterHandlerColorectalTest < ActiveSupport::TestCase
  def setup
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Colorectal::Providers::Manchester::ManchesterHandlerColorectal.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
  end

  # TODO: DOSAGE RECORDS: records need CDNA_REGEX coding. Not seen in real data, but chances are !=0 for this to happen. Records are automatically assigned a normal status if an exonic variant is not found. Need to assess if real normal or possible fails. Normal might be assigned twice of the same gene.
  # TODO: NON-DOSAGE RECORDS: Shall we include in Full Screen tests also genes not listed in exons? That would be against Fiona's initial mapping rules
  # TODO: MLH1/MSH2 might be troublesome to recognise for regexes, even if mostly rescued by other exons

  test 'Targeted positive non dosage record' do
    @importer_stdout, @importer_stderr = capture_io do
      genotypes_exon_molttype_groups = [
        ['Normal', 'c.81C>T', 'MSH6 Ex10', 'MSH6 PREDICTIVE TESTING REPORT'],
        ['c.628-55C\\u003eT poly het', 'Fail', 'MSH2 Ex4a', 'MSH6 PREDICTIVE TESTING REPORT'],
        ['Normal', 'Normal', 'MSH6 Ex4c', 'MSH6 PREDICTIVE TESTING REPORT'],
        ['Fail', 'Fail', 'MSH6 Ex2', 'MSH6 PREDICTIVE TESTING REPORT'],
        ['c.2633T\\u003eA p.V878A', 'Normal', 'MLH1 Ex4d', 'MSH6 PREDICTIVE TESTING REPORT'],
        ['Normal', 'Normal', 'MLH1 Ex5', 'MSH6 PREDICTIVE TESTING REPORT']
      ]

      record = build_raw_record(genotypes_exon_molttype_groups, 'pseudo_id1' => 'bob')
      genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
      genocolorectal.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            Import::Helpers::Colorectal::Providers::R0a::R0aConstants::PASS_THROUGH_FIELDS_COLO)
      @handler.process_fields(record)
      @handler.testscope_from_rawfields(genocolorectal, record)
      mutations = @handler.assign_gene_mutation(genocolorectal, record)
      assert_equal 'Targeted Colorectal Lynch or MMR', genocolorectal.attribute_map['genetictestscope']
      assert mutations.one?
      assert_equal 'c.81C>T', mutations[0].attribute_map['codingdnasequencechange']
    end
  end

  test 'Targeted negative non dosage record' do
    @importer_stdout, @importer_stderr = capture_io do
      genotypes_exon_molttype_groups = [
        ['Normal', 'Normal', 'MSH6 Ex10', 'MSH6 PREDICTIVE TESTING REPORT'],
        ['Normal', 'Fail', 'MSH2 Ex4a', 'MSH6 PREDICTIVE TESTING REPORT'],
        ['Normal', 'Normal', 'MSH6 Ex4c', 'MSH6 PREDICTIVE TESTING REPORT'],
        ['Fail', 'Fail', 'MSH6 Ex2', 'MSH6 PREDICTIVE TESTING REPORT'],
        ['normal', 'Normal', 'MLH1 Ex4d', 'MSH6 PREDICTIVE TESTING REPORT'],
        ['Normal', 'Normal', 'MLH1 Ex5', 'MSH6 PREDICTIVE TESTING REPORT']
      ]

      record = build_raw_record(genotypes_exon_molttype_groups, 'pseudo_id1' => 'bob')
      genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
      genocolorectal.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            Import::Helpers::Colorectal::Providers::R0a::R0aConstants::PASS_THROUGH_FIELDS_COLO)
      @handler.process_fields(record)
      testscope = @handler.testscope_from_rawfields(genocolorectal, record)
      assert_equal 'Targeted Colorectal Lynch or MMR', testscope
      mutations = @handler.assign_gene_mutation(genocolorectal, record)
      assert_equal 'Targeted Colorectal Lynch or MMR', genocolorectal.attribute_map['genetictestscope']
      assert mutations.one?
      assert_equal 1, mutations[0].attribute_map['teststatus']
    end
  end

  test 'Targeted failed non dosage record' do
    @importer_stdout, @importer_stderr = capture_io do
      genotypes_exon_molttype_groups = [
        ['Fail', 'Fail', 'MSH6 Ex10', 'MSH6 PREDICTIVE TESTING REPORT'],
        ['Fail', 'Fail', 'MSH2 Ex4a', 'MSH6 PREDICTIVE TESTING REPORT'],
        ['Fail', 'Fail', 'MSH6 Ex4c', 'MSH6 PREDICTIVE TESTING REPORT'],
        ['Fail', 'Fail', 'MSH6 Ex2', 'MSH6 PREDICTIVE TESTING REPORT'],
        ['Fail', 'Fail', 'MLH1 Ex4d', 'MSH6 PREDICTIVE TESTING REPORT'],
        ['Fail', 'Fail', 'MLH1 Ex5', 'MSH6 PREDICTIVE TESTING REPORT']
      ]

      record = build_raw_record(genotypes_exon_molttype_groups, 'pseudo_id1' => 'bob')
      genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
      genocolorectal.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            Import::Helpers::Colorectal::Providers::R0a::R0aConstants::PASS_THROUGH_FIELDS_COLO)
      @handler.process_fields(record)
      testscope =  @handler.testscope_from_rawfields(genocolorectal, record)
      assert_equal 'Targeted Colorectal Lynch or MMR', testscope
      mutations = @handler.assign_gene_mutation(genocolorectal, record)
      assert_equal 'Targeted Colorectal Lynch or MMR', genocolorectal.attribute_map['genetictestscope']
      assert mutations.one?
      assert_equal 9, mutations[0].attribute_map['teststatus']
    end
  end

  test 'Targeted mixed genes all positive non dosage record' do
    @importer_stdout, @importer_stderr = capture_io do
      genotypes_exon_molttype_groups = [
        ['Normal', 'c.81C>T', 'MSH6 Ex10', 'HNPCC PREDICTIVE TESTING REPORT'],
        ['c.628-55C>T poly het', 'Fail', 'MSH2 Ex4a', 'HNPCC PREDICTIVE TESTING REPORT'],
        ['Normal', 'Normal', 'MSH6 Ex4c', 'HNPCC PREDICTIVE TESTING REPORT'],
        ['Fail', 'Fail', 'MSH6 Ex2', 'HNPCC PREDICTIVE TESTING REPORT'],
        ['c.2633T>A p.V878A', 'Normal', 'MLH1 Ex4d', 'HNPCC PREDICTIVE TESTING REPORT'],
        ['Normal', 'Normal', 'MLH1 Ex5', 'HNPCC PREDICTIVE TESTING REPORT']
      ]

      record = build_raw_record(genotypes_exon_molttype_groups, 'pseudo_id1' => 'bob')
      genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
      genocolorectal.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            Import::Helpers::Colorectal::Providers::R0a::R0aConstants::PASS_THROUGH_FIELDS_COLO)
      @handler.process_fields(record)
      @handler.testscope_from_rawfields(genocolorectal, record)
      mutations = @handler.assign_gene_mutation(genocolorectal, record)
      assert_equal 'Targeted Colorectal Lynch or MMR', genocolorectal.attribute_map['genetictestscope']
      assert_not mutations.one?
      assert_equal 2, mutations[0].attribute_map['teststatus']
      assert_equal 2, mutations[1].attribute_map['teststatus']
      assert_equal 2, mutations[2].attribute_map['teststatus']
    end
  end

  test 'Targeted MSH6 false positive non dosage record' do
    @importer_stdout, @importer_stderr = capture_io do
      genotypes_exon_molttype_groups = [
        ['Normal', 'c.81C>T', 'MSH6 Ex10', 'HNPCC PREDICTIVE TESTING REPORT'],
        ['c.628-55C>T poly het', 'Fail', 'MSH2 Ex4a', 'HNPCC PREDICTIVE TESTING REPORT'],
        ['Normal', 'Normal', 'MSH6 Ex4c', 'HNPCC PREDICTIVE TESTING REPORT'],
        ['Fail', 'Fail', 'MSH6 Ex2', 'HNPCC PREDICTIVE TESTING REPORT'],
        ['c.2633T>A p.V878A', 'Normal', 'MLH1 Ex4d', 'HNPCC PREDICTIVE TESTING REPORT'],
        ['Normal', 'Normal', 'MLH1 Ex5', 'HNPCC PREDICTIVE TESTING REPORT'],
        ['Normal', 'MLH1 c.81C>T', 'MSH6 Ex10', 'HNPCC PREDICTIVE TESTING REPORT']
      ]

      record = build_raw_record(genotypes_exon_molttype_groups, 'pseudo_id1' => 'bob')
      genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
      genocolorectal.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            Import::Helpers::Colorectal::Providers::R0a::R0aConstants::PASS_THROUGH_FIELDS_COLO)
      @handler.process_fields(record)
      @handler.testscope_from_rawfields(genocolorectal, record)
      mutations = @handler.assign_gene_mutation(genocolorectal, record)
      assert_equal 'Targeted Colorectal Lynch or MMR', genocolorectal.attribute_map['genetictestscope']
      assert_not mutations.one?
      assert_equal 1, mutations[0].attribute_map['teststatus']
      assert_equal 2, mutations[1].attribute_map['teststatus']
      assert_equal 2, mutations[2].attribute_map['teststatus']
    end
  end

  test 'Full Screen MSH6 positive MSH2 fail MLH1 normal tests non dosage record' do
    @importer_stdout, @importer_stderr = capture_io do
      genotypes_exon_molttype_groups = [
        ['Normal', 'c.81C>T', 'MSH6 Ex10 NGS', 'LYNCH SYNDROME MUTATION SCREENING REPORT'],
        ['Fail', 'Fail', 'MSH2 Ex4a', 'LYNCH SYNDROME MUTATION SCREENING REPORT'],
        ['Normal', 'Normal', 'MSH6 Ex4c', 'LYNCH SYNDROME MUTATION SCREENING REPORT'],
        ['Fail', 'Fail', 'MSH6 Ex2', 'LYNCH SYNDROME MUTATION SCREENING REPORT'],
        ['Normal', 'Normal', 'MLH1 Ex4d', 'LYNCH SYNDROME MUTATION SCREENING REPORT'],
        ['Normal', 'Normal', 'MLH1 Ex5', 'LYNCH SYNDROME MUTATION SCREENING REPORT']
      ]

      record = build_raw_record(genotypes_exon_molttype_groups, 'pseudo_id1' => 'bob')
      genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
      genocolorectal.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            Import::Helpers::Colorectal::Providers::R0a::R0aConstants::PASS_THROUGH_FIELDS_COLO)
      @handler.process_fields(record)
      mutations = @handler.assign_gene_mutation(genocolorectal, record)
      assert_equal 3, mutations.size
      testscope =  @handler.testscope_from_rawfields(genocolorectal, record)
      assert_equal 'Full screen Colorectal Lynch or MMR', testscope
      assert_equal 2, mutations[0].attribute_map['teststatus']
      assert_equal 9, mutations[1].attribute_map['teststatus']
      assert_equal 1, mutations[2].attribute_map['teststatus']
    end
  end

  test 'Full Screen MSH6 positive MSH2 false positive for MLH1 Tests non dosage record' do
    @importer_stdout, @importer_stderr = capture_io do
      genotypes_exon_molttype_groups = [
        ['Normal', 'c.81C>T', 'MSH6 Ex10 NGS', 'HNPCC MUTATION SCREENING REPORT'],
        ['Normal', 'Fail', 'MSH2 Ex4a', 'HNPCC MUTATION SCREENING REPORT'],
        ['Normal', 'Normal', 'MSH6 Ex4c', 'HNPCC MUTATION SCREENING REPORT'],
        ['Fail', 'Fail', 'MSH6 Ex2', 'HNPCC MUTATION SCREENING REPORT'],
        ['Normal', 'Normal', 'MLH1 Ex4d', 'HNPCC MUTATION SCREENING REPORT'],
        ['MLH1 c.2633T>A p.V878A', 'Normal', 'MSH2 Ex5', 'HNPCC MUTATION SCREENING REPORT']
      ]

      record = build_raw_record(genotypes_exon_molttype_groups, 'pseudo_id1' => 'bob')
      genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
      genocolorectal.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            Import::Helpers::Colorectal::Providers::R0a::R0aConstants::PASS_THROUGH_FIELDS_COLO)
      @logger.expects(:debug).with('STARTING PARSING')
      @logger.expects(:debug).with('IDENTIFIED FALSE POSITIVE FOR MSH2, MLH1, 2633T>A from ["Normal", "Fail", "MLH1 c.2633T>A p.V878A"]')
      @logger.expects(:debug).with('IDENTIFIED MSH2, NORMAL TEST from ["Normal", "Fail", "MLH1 c.2633T>A p.V878A"]')
      @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH2')
      @logger.expects(:debug).with('IDENTIFIED MLH1, NORMAL TEST from ["Normal"]')
      @logger.expects(:debug).with('SUCCESSFUL gene parse for MLH1')
      @logger.expects(:debug).with('DONE TEST')
      @handler.process_fields(record)
      @logger.expects(:debug).with('IDENTIFIED FALSE POSITIVE FOR MSH2, MLH1, 2633T>A from ["Normal", "Fail", "MLH1 c.2633T>A p.V878A"]')
      @logger.expects(:debug).with('IDENTIFIED MSH2, NORMAL TEST from ["Normal", "Fail", "MLH1 c.2633T>A p.V878A"]')
      @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH2')
      @logger.expects(:debug).with('IDENTIFIED MLH1, NORMAL TEST from ["Normal"]')
      @logger.expects(:debug).with('SUCCESSFUL gene parse for MLH1')
      @handler.assign_gene_mutation(genocolorectal, record)
      assert @importer_stderr.blank?
    end
  end

  test 'Full Screen MLH1_MSH2_MSH6_NGS_POOL non dosage record' do
    @importer_stdout, @importer_stderr = capture_io do
      genotypes_exon_molttype_groups = [
        ['MSH2 c.762T>C p.(Asn254Asn) HET, MLH1 Normal, MSH6 Normal', 'Seq MSH2 Ex14 FAIL, MLH1 and MSH6 100% coverage at 100X', 'MLH1_MSH2_MSH6_NGS-POOL', 'LYNCH SYNDROME GENE SCREENING REPORT'],
        ['Normal', 'Fail', 'MSH2 Ex4a', 'LYNCH SYNDROME GENE SCREENING REPORT'],
        ['Normal', 'Normal', 'MSH6 Ex4c', 'LYNCH SYNDROME GENE SCREENING REPORT'],
        ['Fail', 'Fail', 'MSH6 Ex2', 'LYNCH SYNDROME GENE SCREENING REPORT'],
        ['Normal', 'Normal', 'MLH1 Ex4d', 'LYNCH SYNDROME GENE SCREENING REPORT']
      ]

      record = build_raw_record(genotypes_exon_molttype_groups, 'pseudo_id1' => 'bob')
      genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
      genocolorectal.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            Import::Helpers::Colorectal::Providers::R0a::R0aConstants::PASS_THROUGH_FIELDS_COLO)
      @logger.expects(:debug).with('STARTING PARSING')
      @logger.expects(:debug).with('IDENTIFIED FALSE POSITIVE FOR MLH1, MSH2, 762T>C from ["MSH2 c.762T>C p.(Asn254Asn) HET", "NGS Normal", "Normal"]')
      @logger.expects(:debug).with('IDENTIFIED MLH1, NORMAL TEST from ["MSH2 c.762T>C p.(Asn254Asn) HET", "NGS Normal", "Normal"]')
      @logger.expects(:debug).with('SUCCESSFUL gene parse for MLH1')
      @logger.expects(:debug).with('IDENTIFIED MSH2, NORMAL TEST from ["Normal", "NGS Normal", "Fail"]')
      @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH2')
      @logger.expects(:debug).with('IDENTIFIED MSH6, NORMAL TEST from ["Normal", "NGS Normal", "Fail"]')
      @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH6')
      @logger.expects(:debug).with('DONE TEST')
      @handler.process_fields(record)
      @logger.expects(:debug).with('IDENTIFIED FALSE POSITIVE FOR MLH1, MSH2, 762T>C from ["MSH2 c.762T>C p.(Asn254Asn) HET", "NGS Normal", "Normal"]')
      @logger.expects(:debug).with('IDENTIFIED MLH1, NORMAL TEST from ["MSH2 c.762T>C p.(Asn254Asn) HET", "NGS Normal", "Normal"]')
      @logger.expects(:debug).with('SUCCESSFUL gene parse for MLH1')
      @logger.expects(:debug).with('IDENTIFIED MSH2, NORMAL TEST from ["Normal", "NGS Normal", "Fail"]')
      @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH2')
      @logger.expects(:debug).with('IDENTIFIED MSH6, NORMAL TEST from ["Normal", "NGS Normal", "Fail"]')
      @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH6')
      @handler.assign_gene_mutation(genocolorectal, record)
      assert @importer_stderr.blank?
    end
  end

  test 'Dosage record positive result' do
    @importer_stdout, @importer_stderr = capture_io do
      genotypes_exon_molttype_groups = [
        ['MSH2ex8dup', '', 'MSH2 MLPA', 'HNPCC DOSAGE ANALYSIS REPORT'],
        ['Normal', 'Normal', 'MSH6 Ex4c', 'HNPCC DOSAGE ANALYSIS REPORT'],
        ['Normal', 'Normal', 'MLH1 Ex5 mlpa', 'HNPCC DOSAGE ANALYSIS REPORT']
      ]
      record = build_raw_record(genotypes_exon_molttype_groups, 'pseudo_id1' => 'bob')
      genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
      genocolorectal.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            Import::Helpers::Colorectal::Providers::R0a::R0aConstants::PASS_THROUGH_FIELDS_COLO)
      @handler.process_fields(record)
      mutations = @handler.assign_gene_mutation(genocolorectal, record)
      @handler.testscope_from_rawfields(genocolorectal, record)
      assert_equal 'Full screen Colorectal Lynch or MMR', genocolorectal.attribute_map['genetictestscope']
      assert_not mutations.one?
      assert_equal 2, mutations[0].attribute_map['teststatus']
    end
  end

  test 'Dosage record negative result' do
    # Dosage records are parsed only for large exonic variants, and no CDNA_REGEX condition was
    # formulated for them. As expected, this fires up as a negative record.
    # Might think about a DEBUG logger message about it.
    @importer_stdout, @importer_stderr = capture_io do
      genotypes_exon_molttype_groups = [
        ['c.2633T>A p.V878A', 'Normal', 'MSH6 Ex10MLPA', 'LYNCH SYNDROME (MSH6) DOSAGE ANALYSIS REPORT'],
        ['c.628-55C\\u003eT poly het', 'Fail', 'MSH2 Ex4a', 'LYNCH SYNDROME (MSH6) DOSAGE ANALYSIS REPORT'],
        ['Normal', 'Normal', 'MSH6 Ex4c', 'LYNCH SYNDROME (MSH6) DOSAGE ANALYSIS REPORT'],
        ['Fail', 'Fail', 'MSH6 Ex2 MLPA', 'LYNCH SYNDROME (MSH6) DOSAGE ANALYSIS REPORT'],
        ['c.2633T\\u003eA p.V878A', 'Normal', 'MLH1 Ex4d', 'LYNCH SYNDROME (MSH6) DOSAGE ANALYSIS REPORT'],
        ['Normal', 'Normal', 'MLH1 Ex5', 'LYNCH SYNDROME (MSH6) DOSAGE ANALYSIS REPORT']
      ]
      record = build_raw_record(genotypes_exon_molttype_groups, 'pseudo_id1' => 'bob')
      genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
      genocolorectal.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            Import::Helpers::Colorectal::Providers::R0a::R0aConstants::PASS_THROUGH_FIELDS_COLO)
      @handler.process_fields(record)
      @handler.testscope_from_rawfields(genocolorectal, record)
      mutations = @handler.assign_gene_mutation(genocolorectal, record)
      assert_equal 'Full screen Colorectal Lynch or MMR', genocolorectal.attribute_map['genetictestscope']
      assert mutations.one?
      assert_equal 1, mutations[0].attribute_map['teststatus']
    end
  end

  test 'Multiple mutations single gene' do
    @importer_stdout, @importer_stderr = capture_io do
      genotypes_exon_molttype_groups = [
        ['Normal', 'c.81C>T', 'MSH6 Ex10', 'HNPCC PREDICTIVE TESTING REPORT'],
        ['c.628-55C>T poly het', 'Fail', 'MSH2 Ex4a', 'HNPCC PREDICTIVE TESTING REPORT'],
        ['Normal', 'Normal', 'MSH6 Ex4c', 'HNPCC PREDICTIVE TESTING REPORT'],
        ['Fail', 'Fail', 'MSH6 Ex2', 'HNPCC PREDICTIVE TESTING REPORT'],
        ['c.2633T>A p.V878A', 'Normal', 'MLH1 Ex4d', 'HNPCC PREDICTIVE TESTING REPORT'],
        ['c.666A>G', 'Normal', 'MLH1 Ex5', 'HNPCC PREDICTIVE TESTING REPORT']
      ]

      record = build_raw_record(genotypes_exon_molttype_groups, 'pseudo_id1' => 'bob')
      genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
      genocolorectal.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            Import::Helpers::Colorectal::Providers::R0a::R0aConstants::PASS_THROUGH_FIELDS_COLO)
      @handler.process_fields(record)
      mutations = @handler.assign_gene_mutation(genocolorectal, record)
      assert_equal 4, mutations.size
      assert_equal 2744, mutations[2].attribute_map['gene']
      assert_equal 'c.2633T>A', mutations[2].attribute_map['codingdnasequencechange']
      assert_equal 2744, mutations[3].attribute_map['gene']
      assert_equal 'c.666A>G', mutations[3].attribute_map['codingdnasequencechange']
    end
  end

  test 'Overlapping variant single gene' do
    @importer_stdout, @importer_stderr = capture_io do
      genotypes_exon_molttype_groups = [
        ['Normal', 'c.81C>T', 'MSH6 Ex10', 'HNPCC PREDICTIVE TESTING REPORT'],
        ['c.628-55C>T poly het', 'Fail', 'MSH2 Ex4a', 'HNPCC PREDICTIVE TESTING REPORT'],
        ['Normal', 'Normal', 'MSH6 Ex4c', 'HNPCC PREDICTIVE TESTING REPORT'],
        ['Fail', 'Fail', 'MSH6 Ex2', 'HNPCC PREDICTIVE TESTING REPORT'],
        ['c.2628Adel25g', 'Normal', 'MLH1 Ex4d', 'HNPCC PREDICTIVE TESTING REPORT'],
        ['c.2628Adel', 'Normal', 'MLH1 Ex5', 'HNPCC PREDICTIVE TESTING REPORT']
      ]

      record = build_raw_record(genotypes_exon_molttype_groups, 'pseudo_id1' => 'bob')
      genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
      genocolorectal.add_passthrough_fields(record.mapped_fields,
                                            record.raw_fields,
                                            Import::Helpers::Colorectal::Providers::R0a::R0aConstants::PASS_THROUGH_FIELDS_COLO)
      @handler.process_fields(record)
      mutations = @handler.assign_gene_mutation(genocolorectal, record)
      assert_equal 3, mutations.size
      assert_equal 2808, mutations[0].attribute_map['gene']
      assert_equal 2804, mutations[1].attribute_map['gene']
      assert_equal 2744, mutations[2].attribute_map['gene']
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
      disease: 'HNPCC' }
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
