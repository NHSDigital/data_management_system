require 'test_helper'

class LeedsHandlerTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Brca::Core::GenotypeBrca.new(@record)
    @extractor = Import::Brca::Providers::Leeds::ReportExtractor::GenotypeAndReportExtractor.new
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Brca::Providers::Leeds::LeedsHandler.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
  end

  test 'stdout reports missing extract path' do
    assert_match(/could not extract path to corrections file for/i, @importer_stdout)
  end

  test 'add_cdna_change_from_report' do
    @logger.expects(:debug).with('SUCCESSFUL cdna change parse for: 5198A>G')
    @handler.add_cdna_change_from_report(@genotype, @record)
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.mapped_fields['report'] = 'E;OUHF;A`HFD ;UFHA;S83UROQW QWURHFS;AY093 ;WQFSAH; SA'
    @logger.expects(:debug).with('FAILED cdna change parse for: E;OUHF;A`HFD ;'\
                                 'UFHA;S83UROQW QWURHFS;AY093 ;WQFSAH; SA')
    @handler.add_cdna_change_from_report(@genotype, broken_record)
  end

  test 'add_gene_cdna_protein_from_report' do
    @logger.expects(:debug).with('SUCCESSFUL gene parse for  BRCA1')
    @logger.expects(:debug).with('SUCCESSFUL cdna change parse for:  BRCA1, 5198A>G,')
    @handler.add_gene_cdna_protein_from_report(@genotype, @record)
    broken_record = build_raw_record('pseudo_id1' => 'bob')
    broken_record.mapped_fields['report'] = 'E;OUHF;A`HFD ;UFHA;S83UROQW QWURHFS;AY093 ;WQFSAH; SA'
    @logger.expects(:debug).with('FAILED gene,cdna,protein impact parse from report')
    @handler.add_gene_cdna_protein_from_report(@genotype, broken_record)
  end

  test 'double_positives' do
    report = Maybe([@record.raw_fields['report'],
                    @record.mapped_fields['report'],
                    @record.raw_fields['firstofreport']].
                     reject(&:nil?).first).or_else('') # la report_string
    geno = Maybe(@record.raw_fields['genotype']).
           or_else(Maybe(@record.raw_fields['report_result']).
           or_else(''))
    @extractor.process(geno, report, @genotype)
    assert_equal 1, @extractor.process(geno, report, @genotype).size
    normal_record = build_raw_record_normal('pseudo_id1' => 'bob')
    normal_genotype = Import::Brca::Core::GenotypeBrca.new(normal_record)
    normal_report = Maybe([normal_record.raw_fields['report'],
                           normal_record.mapped_fields['report'],
                           normal_record.raw_fields['firstofreport']].
                    reject(&:nil?).first).or_else('') # la report_string
    normal_geno = Maybe(normal_record.raw_fields['genotype']).
                  or_else(Maybe(normal_record.raw_fields['report_result']).
                  or_else(''))
    @extractor.process(normal_geno, normal_report, normal_genotype)
    assert_equal 2, @extractor.process(normal_geno, normal_report, normal_genotype).size
  end

  private

  def build_raw_record_normal(options = {})
    default_options = {
      'pseudo_id1' => '',
      'pseudo_id2' => '',
      'encrypted_demog' => '',
      'clinical.to_json' => clinical_json_normal,
      'encrypted_rawtext_demog' => '',
      'rawtext_clinical.to_json' => rawtext_clinical_json_normal
    }

    Import::Brca::Core::RawRecord.new(default_options.merge!(options))
  end

  def clinical_json
    { sex: '2',
      consultantcode: 'Consultant Code',
      providercode: 'Provider Code',
      receiveddate: '2019-10-25T00:00:00.000+01:00',
      authoriseddate: '2019-11-25T00:00:00.000+00:00',
      servicereportidentifier: 'Service Report Identifier',
      sortdate: '2019-10-25T00:00:00.000+01:00',
      genetictestscope: 'R208.1',
      specimentype: '5',
      report: 'This patient has been screened for variants in BRCA1 and BRCA2 by '\
              'sequence and dosage analysis.' \
              'This patient is heterozygous for the '\
              'BRCA1 sequence variant c.5198A>G p.(Asp1733Gly). '\
              'This variant involves a moderately-conserved protein position. '\
              'It is found in population control sets at low frequency, '\
              'and functional studies suggest that '\
              'the resultant protein is functional². Evaluation of the available evidence regarding the '\
              'pathogenicity of this variant remains inconclusive; it is considered to be a variant of '\
              'uncertain significance. Therefore, predictive testing is not indicated for relatives.',
      requesteddate: '2019-10-25T00:00:00.000+01:00',
      age: 999 }.to_json
  end

  def rawtext_clinical_json
    { sex: 'F',
      'reffac.name' => 'Hospital Name',
      provider_address: 'Provider Address',
      providercode: 'Provider Code',
      referringclinicianname: 'Consultant Name',
      consultantcode: 'Consultant Code',
      servicereportidentifier: 'Service Report Identifier',
      patienttype: 'NHS',
      moleculartestingtype: 'R208.1',
      indicationcategory: 'R208',
      genotype: 'BRCA MS - Diag C3',
      report: 'This patient has been screened for variants in BRCA1 and BRCA2 by '\
              'sequence and dosage analysis.' \
              'This patient is heterozygous for the '\
              'BRCA1 sequence variant c.5198A>G p.(Asp1733Gly). '\
              'This variant involves a moderately-conserved protein position. '\
              'It is found in population control sets at low frequency, and functional studies suggest that '\
              'the resultant protein is functional². Evaluation of the available evidence regarding the '\
              'pathogenicity of this variant remains inconclusive; it is considered to be a variant of '\
              'uncertain significance. Therefore, predictive testing is not indicated for relatives.',
      receiveddate: '2019-10-25 00:00:00',
      requesteddate: '2019-10-25 00:00:00',
      authoriseddate: '2019-11-25 00:00:00',
      specimentype: 'Blood' }.to_json
  end

  def clinical_json_normal
    { sex: '2',
      consultantcode: 'Consultant Code',
      providercode: 'Provider Code',
      receiveddate: '2019-10-25T00:00:00.000+01:00',
      authoriseddate: '2019-11-25T00:00:00.000+00:00',
      servicereportidentifier: 'Service Report Identifier',
      sortdate: '2019-10-25T00:00:00.000+01:00',
      genetictestscope: 'R208.1',
      specimentype: '5',
      report: 'This patient has been screened for BRCA1 and BRCA2 '\
              'mutations by sequence analysis and MLPA. No pathogenic mutation was identified.',
      requesteddate: '2019-10-25T00:00:00.000+01:00',
      age: 999 }.to_json
  end

  def rawtext_clinical_json_normal
    { sex: 'F',
      'reffac.name' => 'Hospital Name',
      provider_address: 'Provider Address',
      providercode: 'Provider Code',
      referringclinicianname: 'Consultant Name',
      consultantcode: 'Consultant Code',
      servicereportidentifier: 'Service Report Identifier',
      patienttype: 'NHS',
      moleculartestingtype: 'R208.1',
      indicationcategory: 'R208',
      genotype: 'Normal B1/B2 - UNAFFECTED',
      report: 'This patient has been screened for BRCA1 and BRCA2 '\
              'mutations by sequence analysis and MLPA. No pathogenic mutation was identified.',
      receiveddate: '2019-10-25 00:00:00',
      requesteddate: ' 2019-10-25 00:00:00',
      authoriseddate: '2019-11-25 00:00:00',
      specimentype: 'Blood' }.to_json
  end
end
