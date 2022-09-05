require 'test_helper'
#require 'import/genotype.rb'
#require 'import/colorectal/core/genotype_mmr.rb'
#require 'import/brca/core/provider_handler'
#require 'import/storage_manager/persister'

class LondonKgcHandlerColorectalTest < ActiveSupport::TestCase
  def setup
    @record   = build_raw_record('pseudo_id1' => 'bob')
    @genotype = Import::Colorectal::Core::Genocolorectal.new(@record)
    # TODO: Fully qualify CambridgeHandler in cambridge_handler.rb
    @importer_stdout, @importer_stderr = capture_io do
      @handler = Import::Colorectal::Providers::LondonKgc::LondonKgcHandlerColorectal.new(EBatch.new)
    end
    @logger = Import::Log.get_logger
  end


  test 'process_lynchgenes with no mutation' do
    genemutation_lynch_record = build_raw_record('pseudo_id1' => 'bob')
    genemutation_lynch_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text'] = 'Colorectal Cancer;Trusight Cancer panel'
    clinicomm = genemutation_lynch_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text']
    raw_genotype = genemutation_lynch_record.raw_fields['genotype']
    genotypes = []
    @logger.expects(:debug).with('Found no mutation in broad lynch genes')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: MLH1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MLH1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: MSH2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: MSH6')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH6')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: EPCAM')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for EPCAM')
    @handler.process_lynchgenes(raw_genotype, clinicomm, @genotype, genotypes)
    assert_equal 4, genotypes.size
  end

  test 'process_lynchgenes with cdna mutation' do
    genemutation_lynch_record = build_raw_record('pseudo_id1' => 'bob')
    genemutation_lynch_record.raw_fields['genotype'] = 'MUTYH c.1438G>T, p.(Glu480*) het'
    genemutation_lynch_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text'] = 'Colorectal Cancer;Trusight Cancer panel'
    clinicomm = genemutation_lynch_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text']
    raw_genotype = genemutation_lynch_record.raw_fields['genotype']
    genotypes = []
    @logger.expects(:debug).with('Found BROAD LYNCH dna mutation in [["MUTYH"]] LYNCH RELATED GENE(s) in position [["1438G>T"]] with impact [["Glu480*"]]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for positive test for: MUTYH, 1438G>T, Glu480*')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MUTYH')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: MLH1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MLH1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: MSH2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: MSH6')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH6')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: EPCAM')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for EPCAM')
    @handler.process_lynchgenes(raw_genotype, clinicomm, @genotype, genotypes)
    assert_equal 5, genotypes.size
  end

  test 'process_lynchgenes with chromosomal aberration' do
    chromosomemutation_lynch_record = build_raw_record('pseudo_id1' => 'bob')
    chromosomemutation_lynch_record.raw_fields['genotype'] = 'MSH2 ex1-6 duplication'
    chromosomemutation_lynch_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text'] = 'Lynch Syndrome;Trusight Cancer panel'
    clinicomm = chromosomemutation_lynch_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text']
    raw_genotype = chromosomemutation_lynch_record.raw_fields['genotype']
    genotypes = []
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: MLH1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MLH1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: MSH6')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH6')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: EPCAM')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for EPCAM')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH2')
    @handler.process_lynchgenes(raw_genotype, clinicomm, @genotype, genotypes)
    assert_equal 4, genotypes.size
  end

  test 'process_lynchgenes with mixed cdna mutation and chromosomal aberration' do
    chromosomecdnamutation_lynch_record = build_raw_record('pseudo_id1' => 'bob')
    chromosomecdnamutation_lynch_record.raw_fields['genotype'] = 'MSH2 exon 1-6 deletion plus MSH6 c.1847C>G p.Pro616Arg'
    chromosomecdnamutation_lynch_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text'] = 'Lynch Syndrome;Trusight Cancer panel'
    clinicomm = chromosomecdnamutation_lynch_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text']
    raw_genotype = chromosomecdnamutation_lynch_record.raw_fields['genotype']
    genotypes = []
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: MLH1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MLH1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: EPCAM')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for EPCAM')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH6')
    @handler.process_lynchgenes(raw_genotype, clinicomm, @genotype, genotypes)
    assert_equal 4, genotypes.size
  end

  test 'process_specific_lynchgenes with no mutation' do
    nomutation_lynchspecific_record = build_raw_record('pseudo_id1' => 'bob')
    nomutation_lynchspecific_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text'] = 'Loss of MSH2 and MSH6 on IHC + history of endometrial and ovarian cancer'
    clinicomm = nomutation_lynchspecific_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text']
    raw_genotype = nomutation_lynchspecific_record.raw_fields['genotype']
    genotypes = []
    @logger.expects(:debug).with('Found no mutation in lynch specific genesGenes LYNCH SPECIFIC ["MSH2", "MSH6"] are normal')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: MSH2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: MSH6')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH6')
    @handler.process_specific_lynchgenes(raw_genotype, clinicomm, @genotype, genotypes)
    assert_equal 2, genotypes.size
  end

  test 'process_specific_lynchgenes with cdna mutation' do
    cdnamutation_lynchspecific_record = build_raw_record('pseudo_id1' => 'bob')
    cdnamutation_lynchspecific_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text'] = 'Loss of MSH2 and MSH6 on IHC + history of endometrial and ovarian cancer'
    cdnamutation_lynchspecific_record.raw_fields['genotype'] = 'MSH6 c.3261dup p.(Phe1088Leufs*5)'
    clinicomm = cdnamutation_lynchspecific_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text']
    raw_genotype = cdnamutation_lynchspecific_record.raw_fields['genotype']
    genotypes = []
    @logger.expects(:debug).with('Found SPECIFIC LYNCH dna mutation in [["MSH6"]] LYNCH RELATED GENE(s) in position [["3261dup p"]] with impact [["Phe1088Leufs*"]]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for positive test for: MSH6, 3261dup p, Phe1088Leufs*')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH6')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN LYNCH SPECIFIC for: MSH2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH2')
    @handler.process_specific_lynchgenes(raw_genotype, clinicomm, @genotype, genotypes)
    assert_equal 2, genotypes.size
  end

  test 'process_specific_lynchgenes with chromosome aberration' do
    chromosomemutation_lynchspecific_record = build_raw_record('pseudo_id1' => 'bob')
    chromosomemutation_lynchspecific_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text'] = 'Loss of MSH2 and MSH6 on IHC + history of endometrial and ovarian cancer'
    chromosomemutation_lynchspecific_record.raw_fields['genotype'] = 'MSH2 exon 4 deletion'
    clinicomm = chromosomemutation_lynchspecific_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text']
    raw_genotype = chromosomemutation_lynchspecific_record.raw_fields['genotype']
    genotypes = []
    @logger.expects(:debug).with('Found LYNCH_SPECdel in MSH2 LYNCH RELATED GENE at position 4')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for negative test for: MSH6')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH6')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH2')
    @handler.process_specific_lynchgenes(raw_genotype, clinicomm, @genotype, genotypes)
    assert_equal 2, genotypes.size
  end

  test 'process_specific_lynchgenes with cdna mutation and chromosomal aberration' do
    cdna_chromosomemutation_lynchspecific_record = build_raw_record('pseudo_id1' => 'bob')
    cdna_chromosomemutation_lynchspecific_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text'] = 'Loss MLH1- PMS2'
    cdna_chromosomemutation_lynchspecific_record.raw_fields['genotype'] = 'MLH1 c.1852_1854del p.Lys618del and PMS2 duplication exon 16-19'
    clinicomm = cdna_chromosomemutation_lynchspecific_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text']
    raw_genotype = cdna_chromosomemutation_lynchspecific_record.raw_fields['genotype']
    genotypes = []
    @logger.expects(:debug).with('Found LYNCH_SPEC del in ["MLH1"] LYNCH RELATED GENE at position 16-19 and Mutation 1852_1854del in gene ["MLH1"] at position [["1852_1854del"]] with impact [["Lys618del "]]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MLH1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for PMS2')
    @handler.process_specific_lynchgenes(raw_genotype, clinicomm, @genotype, genotypes)
    assert_equal 2, genotypes.size
  end

  test 'process_non_lynch_genes with no mutation on one gene' do
    nomutation_nonlynch_onegene_record = build_raw_record('pseudo_id1' => 'bob')
    nomutation_nonlynch_onegene_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text'] = 'MUTYH-associated Polyposis'
    clinicomm = nomutation_nonlynch_onegene_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text']
    raw_genotype = nomutation_nonlynch_onegene_record.raw_fields['genotype']
    genotypes = []
    @logger.expects(:debug).with('Found no mutation; Genes ["MUTYH"] are normal')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: MUTYH')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MUTYH')
    @handler.process_non_lynch_genes(raw_genotype, clinicomm, @genotype, genotypes)
    assert_equal 1, genotypes.size
  end

  test 'process_non_lynch_genes with cdna mutation on one gene' do
    cdnamutation_nonlynch_onegene_record = build_raw_record('pseudo_id1' => 'bob')
    cdnamutation_nonlynch_onegene_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text'] = 'MUTYH-associated Polyposis'
    cdnamutation_nonlynch_onegene_record.raw_fields['genotype'] = 'MUTYH c.666C>g; p.Thr1234*'
    clinicomm = cdnamutation_nonlynch_onegene_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text']
    raw_genotype = cdnamutation_nonlynch_onegene_record.raw_fields['genotype']
    genotypes = []
    @logger.expects(:debug).with('Found NON-LYNCH dna mutation in ["MUTYH"] LYNCH RELATED GENE(s) in position [["666C>g"]] with impact [["Thr1234*"]]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for positive test for: MUTYH, 666C>g, Thr1234*')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MUTYH')
    @handler.process_non_lynch_genes(raw_genotype, clinicomm, @genotype, genotypes)
    assert_equal 1, genotypes.size
  end

  test 'process_non_lynch_genes with no mutation on multiple genes' do
    nomutation_nonlynch_multiplegenes_record = build_raw_record('pseudo_id1' => 'bob')
    nomutation_nonlynch_multiplegenes_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text'] = 'MUTYH-associated Polyposis;Trusight Cancer panel: APC, MUTYH;Polyp panel'
    clinicomm = nomutation_nonlynch_multiplegenes_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text']
    raw_genotype = nomutation_nonlynch_multiplegenes_record.raw_fields['genotype']
    genotypes = []
    @logger.expects(:debug).with('Found no mutation; Genes ["MUTYH", "APC"] are normal')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: MUTYH')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MUTYH')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: APC')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for APC')
    @handler.process_non_lynch_genes(raw_genotype, clinicomm, @genotype, genotypes)
    assert_equal 2, genotypes.size
  end

  test 'process_non_lynch_genes with cdna mutation on multiple genes' do
    cdnamutation_nonlynch_multiplegenes_record = build_raw_record('pseudo_id1' => 'bob')
    cdnamutation_nonlynch_multiplegenes_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text'] = 'MUTYH-associated Polyposis;Trusight Cancer panel: APC, MUTYH;Polyp panel'
    cdnamutation_nonlynch_multiplegenes_record.raw_fields['genotype'] = 'APC c.3827C>A; p.Ser1276*'
    clinicomm = cdnamutation_nonlynch_multiplegenes_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text']
    raw_genotype = cdnamutation_nonlynch_multiplegenes_record.raw_fields['genotype']
    genotypes = []
    @logger.expects(:debug).with('Found NON-LYNCH dna mutation in ["APC"] LYNCH RELATED GENE(s) in position [["3827C>A"]] with impact [["Ser1276*"]]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for positive test for: APC, 3827C>A, Ser1276*')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for APC')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: ["MUTYH"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: MUTYH')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MUTYH')
    @handler.process_non_lynch_genes(raw_genotype, clinicomm, @genotype, genotypes)
    assert_equal 2, genotypes.size
  end

  test 'process_non_lynch_genes with chromosomal aberration' do
    chromosomemutation_nonlynch_multiplegenes_record = build_raw_record('pseudo_id1' => 'bob')
    chromosomemutation_nonlynch_multiplegenes_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text'] = 'MUTYH-associated Polyposis;Trusight Cancer panel: APC, MUTYH;Polyp panel'
    chromosomemutation_nonlynch_multiplegenes_record.raw_fields['genotype'] = 'MUTYH exon 14-16 duplication'
    clinicomm = chromosomemutation_nonlynch_multiplegenes_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text']
    raw_genotype = chromosomemutation_nonlynch_multiplegenes_record.raw_fields['genotype']
    genotypes = []
    @logger.expects(:debug).with('Found NON-LYNCH CHROMOSOME dup in MUTYH NON-LYNCH GENE at position 14-16')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: ["APC"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: APC')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for APC')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MUTYH')
    @handler.process_non_lynch_genes(raw_genotype, clinicomm, @genotype, genotypes)
    assert_equal 2, genotypes.size
  end

  test 'process_non_lynch_genes with mixed cdna Chromosomal aberration multiple genes' do
    cdna_chromosomemutation_nonlynch_multiplegenes_record = build_raw_record('pseudo_id1' => 'bob')
    cdna_chromosomemutation_nonlynch_multiplegenes_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text'] = 'MUTYH-associated Polyposis;Trusight Cancer panel: APC, MUTYH;Polyp panel'
    cdna_chromosomemutation_nonlynch_multiplegenes_record.raw_fields['genotype'] = 'APC c.666A>O p.Ser456Thr MUTYH exon 14-16 duplication'
    clinicomm = cdna_chromosomemutation_nonlynch_multiplegenes_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text']
    raw_genotype = cdna_chromosomemutation_nonlynch_multiplegenes_record.raw_fields['genotype']
    genotypes = []
    @logger.expects(:debug).with('SUCCESSFUL gene parse for APC')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MUTYH')
    @handler.process_non_lynch_genes(raw_genotype, clinicomm, @genotype, genotypes)
    assert_equal 2, genotypes.size
  end

  test 'process_union_lynchgenes with no mutation' do
    # No Mutation
    nomutation_lynch_nonlynch_record = build_raw_record('pseudo_id1' => 'bob')
    nomutation_lynch_nonlynch_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text'] = 'Colorectal Cancer;Lynch Syndrome;Polyp panel including POLD/E.;req. STK11 testing'
    clinicomm = nomutation_lynch_nonlynch_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text']
    raw_genotype = nomutation_lynch_nonlynch_record.raw_fields['genotype']
    genotypes = []
    @logger.expects(:debug).with('Found NON_LYNCH and LYNCH test')
    @logger.expects(:debug).with('Found no mutation; Genes ["MLH1", "MSH2", "MSH6", "EPCAM", "APC", "MUTYH", "POLD1", "POLE", "STK11"] are normal')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: MLH1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MLH1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: MSH2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: MSH6')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH6')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: EPCAM')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for EPCAM')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: APC')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for APC')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: MUTYH')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MUTYH')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: POLD1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for POLD1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: POLE')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for POLE')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: STK11')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for STK11')
    @handler.process_union_lynchgenes(raw_genotype, clinicomm, @genotype, genotypes)
    assert_equal 9, genotypes.size
  end

  test 'process_union_lynchgenes with cdna Mutation' do
    cdnamutation_lynch_nonlynch_record = build_raw_record('pseudo_id1' => 'bob')
    cdnamutation_lynch_nonlynch_record.raw_fields['genotype'] = 'MUTYH c.1438G>T p.(Glu480*) hom'
    cdnamutation_lynch_nonlynch_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text'] = 'Colorectal Cancer;Lynch Syndrome;Polyp panel including POLD/E.;req. STK11 testing'
    clinicomm = cdnamutation_lynch_nonlynch_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text']
    raw_genotype = cdnamutation_lynch_nonlynch_record.raw_fields['genotype']
    genotypes = []
    @logger.expects(:debug).with('Found NON_LYNCH and LYNCH test')
    @logger.expects(:debug).with('Found BROAD LYNCH dna mutation in [["MUTYH"]] LYNCH and NON-LYNCH RELATED GENE(s) in position [["1438G>T"]] with impact [["Glu480*"]]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for positive test for: MUTYH, 1438G>T, Glu480*')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MUTYH')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test in LYNCH AND NON-LYNCH for: ["MLH1", "MSH2", "MSH6", "EPCAM", "APC", "POLD1", "POLE", "STK11"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test in LYNCHAND NON-LYNCH for: MLH1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MLH1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test in LYNCHAND NON-LYNCH for: MSH2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test in LYNCHAND NON-LYNCH for: MSH6')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH6')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test in LYNCHAND NON-LYNCH for: EPCAM')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for EPCAM')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test in LYNCHAND NON-LYNCH for: APC')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for APC')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test in LYNCHAND NON-LYNCH for: POLD1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for POLD1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test in LYNCHAND NON-LYNCH for: POLE')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for POLE')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test in LYNCHAND NON-LYNCH for: STK11')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for STK11')
    @handler.process_union_lynchgenes(raw_genotype, clinicomm, @genotype, genotypes)
    assert_equal 9, genotypes.size
  end

  test 'process_union_lynchgenes with cdna chromosome aberration' do
    chromosomemutation_lynch_nonlynch_record = build_raw_record('pseudo_id1' => 'bob')
    chromosomemutation_lynch_nonlynch_record.raw_fields['genotype'] = 'STK11 exon 2-7 deletion'
    chromosomemutation_lynch_nonlynch_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text'] = 'Colorectal Cancer;Lynch Syndrome;Polyp panel including POLD/E.;req. STK11 testing'
    clinicomm = chromosomemutation_lynch_nonlynch_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text']
    raw_genotype = chromosomemutation_lynch_nonlynch_record.raw_fields['genotype']
    genotypes = []
    @logger.expects(:debug).with('Found NON_LYNCH and LYNCH test')
    @logger.expects(:debug).with('Found LYNCH CHROMOSOMEdel in STK11 LYNCH and NON-LYNCH RELATED GENE(s) at position 2-7')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: ["MLH1", "MSH2", "MSH6", "EPCAM", "APC", "MUTYH", "POLD1", "POLE"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: MLH1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MLH1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: MSH2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: MSH6')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH6')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: EPCAM')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for EPCAM')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: APC')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for APC')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: MUTYH')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MUTYH')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: POLD1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for POLD1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: POLE')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for POLE')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for STK11')
    @handler.process_union_lynchgenes(raw_genotype, clinicomm, @genotype, genotypes)
    assert_equal 9, genotypes.size
  end

  test 'process_union_lynchgenes with mixed cdna and chromosome mutation' do
    cdnachromosomemutation_lynch_nonlynch_record = build_raw_record('pseudo_id1' => 'bob')
    cdnachromosomemutation_lynch_nonlynch_record.raw_fields['genotype'] = 'MLH1 c.666A>T p.Ser480* hom and STK11 exon 2-7 deletion'
    cdnachromosomemutation_lynch_nonlynch_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text'] = 'Colorectal Cancer;Lynch Syndrome;Polyp panel including POLD/E.;req. STK11 testing'
    clinicomm = cdnachromosomemutation_lynch_nonlynch_record.raw_fields['all clinical comments (semi colon separated).all clinical comment text']
    raw_genotype = cdnachromosomemutation_lynch_nonlynch_record.raw_fields['genotype']
    genotypes = []
    @logger.expects(:debug).with('Found NON_LYNCH and LYNCH test')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: ["MSH2", "MSH6", "EPCAM", "APC", "MUTYH", "POLD1", "POLE"]')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: MSH2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH2')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: MSH6')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MSH6')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: EPCAM')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for EPCAM')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: APC')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for APC')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: MUTYH')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MUTYH')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: POLD1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for POLD1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: POLE')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for POLE')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for MLH1')
    @logger.expects(:debug).with('SUCCESSFUL gene parse for STK11')
    @handler.process_union_lynchgenes(raw_genotype, clinicomm, @genotype, genotypes)
    assert_equal 9, genotypes.size
  end

  private

  def clinical_json
    { sex: '2',
      providercode: 'Provider Code',
      collecteddate: '2016-03-22T00:00:00.000+00:00',
      receiveddate: '2016-03-23T00:00:00.000+00:00',
      authoriseddate: '2016-07-13T00:00:00.000+01:00',
      servicereportidentifier: 'Service Report Identifier',
      specimentype: '5',
      genotype: 'No mutation detected',
      variantpathclass: 'Normal/Wild type',
      age: 999 }.to_json
  end

  def rawtext_clinical_json
    { genotype: 'No mutation detected',
      variantpathclass: 'Normal/Wild type',
      'test type 1' => 'Next Gen Sequencing',
      'test type 2' => '',
      sex: 'F',
      'clinician desc' => 'Polyposis Registry',
      consultantcode: 'Consultant Code',
      'specialty desc' => 'UNKNOWN',
      providercode: 'Watford Road',
      'source desc' => 'Source description',
      'source ccg desc' => 'Source Description',
      servicereportidentifier: 'Service Report Identifier',
      specimentype: 'Blood',
      collecteddate: '2016-03-22 00:00:00',
      receiveddate: '2016-03-23 00:00:00',
      authoriseddate: '2016-07-13 00:00:00',
      'all clinical comments (semi colon separated).all clinical comment text' => 'Colorectal Cancer;MUTYH-associated Polyposis;Trusight Cancer panel' }.to_json
  end
end
