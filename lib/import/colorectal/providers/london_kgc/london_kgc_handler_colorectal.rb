require 'possibly'
require 'import/storage_manager/persister'
require 'import/brca/core/provider_handler'
require 'pry'

module Import
  module Colorectal
    module Providers
      module LondonKgc
        # London KGC importer
        class LondonKgcHandlerColorectal < Import::Brca::Core::ProviderHandler
          PASS_THROUGH_FIELDS_COLO = %w[age sex consultantcode collecteddate
                                        receiveddate authoriseddate servicereportidentifier
                                        providercode ] .freeze

          def initialize(batch)
            @failed_genocolorectal_counter = 0
            @successful_gene_counter = 0
            @failed_gene_counter = 0
            @negative_test = 0
            @positive_test = 0
            super
          end

          LYNCH = /Trusight Cancer panel\: lynch syndrome|Bowel Cancer|Colorectal Cancer|Lynch Syndrome|Lynch syndrome/i .freeze
          LYNCH_SPECIFIC = /(?<override>for MSH6 testing|loss MLH1 and PMS2|Loss MLH1\- PMS2|Loss of MSH2 and MSH6 on IHC \+ history of endometrial and ovarian cancer|MLH1 and PMS2|MLH1 testing|MSH1\/MSH2\/MSH6 testing|msh2 \& msh6 TESTING|MSH2 and MSH6 \(if req\'d\)|MSH2 exon 5 reanalysis|MSH2 reanalysis requested|MSH6 testing)/i .freeze
          MSH2_6 = /Loss MSH2\/6/i .freeze
          NON_LYNCH_REGEX = /Familial Adenomatous Polyposis|MAP|MUTYH common testing|MUTYH\-associated Polyposis|Trusight Cancer panel\: APC\, MUTYH|Polyp panel including POLD\/E\.|Polyp panel|Polyposis genes|MUTYH-associated Polyposis\, POLD1\/POLE|Pol Proof-reading Polyposis|POLE\/POLD1|pole\/pold1 testing|POLE\/POLD1 testing as well|Peutz Jeghers Syndrome|req\. STK11 testing|stk11 testing|Cowden syndrome|PTEN Harmatoma Tumour Syn\.|For PTEN and renal cancer panel in Birmingham|Juvenile Polyposis Syndrome|SMAD4 testing requested|Hered Mixed Polyposis|GREM1|Full MYH and GREM1|Requeste full MYH and GREM1/i .freeze
          EXON_REGEX = /ex(?:on) (?<exno>[0-9]{1,2}(-[0-9]{1,2})?).+(?<deldupins>(del|dup|ins))|(?<deldupins>(del|dup|ins)).+ex(?:on(s)?) (?<exno>[0-9]{1,2}(-[0-9]{1,2})?)/i .freeze
          CDNA_REGEX = /c\.(?<dna>[0-9]+([a-z]+|[^[:alnum:]])([0-9]+[a-z]+>[a-z]|[0-9]+[a-z]+|[^[:alnum:]][a-z]+))/i .freeze
          PROTEIN_REGEX_COLO = /p\.(\(|\[)?(?<impact>[a-z]+[0-9]+([a-z]+[^[:alnum:]]|[a-z]+|[^[:alnum:]]))/i .freeze
          COLORECTAL_GENES_REGEX = /(?<colorectal>APC|
                                                BMPR1A|
                                                EPCAM|
                                                MLH1|
                                                MSH2|
                                                MSH6|
                                                MUTYH|
                                                PMS2|
                                                POLD1|
                                                POLE|
                                                PTEN|
                                                SMAD4|
                                                STK11)/xi .freeze

          NON_LYNCH_MAP = { 'Familial Adenomatous Polyposis' => 'APC',
                            'MAP' => 'MUTYH',
                            'MUTYH common testing' => 'MUTYH',
                            'MUTYH-associated Polyposis' => 'MUTYH',
                            'Trusight Cancer panel: APC, MUTYH' => %w[APC MUTYH],
                            'Polyp panel' => %w[APC MUTYH],
                            'Polyposis genes' => %w[APC MUTYH],
                            'Polyp panel including POLD/E.' => %w[APC MUTYH POLD1 POLE],
                            'MUTYH-associated Polyposis, POLD1/POLE' => %w[MUTYH POLD1 POLE],
                            'Pol Proof-reading Polyposis' => %w[POLD1 POLE],
                            'POLE/POLD1' => %w[POLD1 POLE],
                            'pole/pold1 testing' => %w[POLD1 POLE],
                            'POLE/POLD1 testing as well' => %w[POLD1 POLE],
                            'Peutz Jeghers Syndrome' => 'STK11',
                            'req. STK11 testing' => 'STK11',
                            'stk11 testing' => 'STK11',
                            'Cowden syndrome' => 'PTEN',
                            'PTEN Harmatoma Tumour Syn.' => 'PTEN',
                            'For PTEN and renal cancer panel in Birmingham' => 'PTEN',
                            'Juvenile Polyposis Syndrome' => %w[SMAD4 BMPR1A],
                            'SMAD4 testing requested' => 'SMAD4',
                            'Hered Mixed Polyposis' => 'GREM1',
                            'GREM1' => 'GREM1',
                            'Full MYH and GREM1' => %w[MUTYH GREM1],
                            'Requeste full MYH and GREM1' => %w[MUTYH GREM1],
                            'requested APC- MUTYH-SMAD4-MLH1- MLH2- MLH6 testing' => %w[APC MUTYH SMAD4 MLH1 MSH2 MSH6],
                            'Trusight Cancer panel: APC, MUTYH, STK11, PTEN, JPS' => %w[APC MUTYH STK11 PTEN SMAD4 BMPR1A] } .freeze

          def process_fields(record)
            @lines_processed += 1 # TODO: factor this out to be automatic across handlers
            genocolorectal = Import::Colorectal::Core::Genocolorectal.new(record)
            genocolorectal.add_passthrough_fields(record.mapped_fields,
                                                  record.raw_fields,
                                                  PASS_THROUGH_FIELDS_COLO)
            genocolorectal.add_test_scope(:full_screen)
            res = extract_lynch_from_record(genocolorectal, record)
            res.map { |cur_genotype| @persister.integrate_and_store(cur_genotype) }
          end

          def extract_lynch_from_record(genocolorectal, record)
            clinicomm = record.raw_fields['all clinical comments (semi colon separated).all clinical comment text']
            raw_genotype = record.raw_fields['genotype']
            genotypes = []
            # This block is to see if there are BROAD MLH1, MSH2, MSH6, EPCAM records
            if clinicomm.scan(LYNCH).size > 0 && clinicomm !~ LYNCH_SPECIFIC \
              && clinicomm !~ NON_LYNCH_REGEX && clinicomm !~ MSH2_6
              lynchgenes(raw_genotype, clinicomm, genocolorectal, genotypes)
              #This block is to see if there are SPECIFIC MLH1, MSH2, MSH6, EPCAM records
            elsif clinicomm.scan(LYNCH_SPECIFIC).size > 0 \
              && clinicomm !~ NON_LYNCH_REGEX && clinicomm !~ MSH2_6
              lynchgenes_spec = clinicomm.scan(COLORECTAL_GENES_REGEX).flatten.map(&:upcase)
              @logger.debug "FOUND LYNCH SPECIFIC genes #{lynchgenes_spec}"
                lynch_specific(raw_genotype, clinicomm, genocolorectal, genotypes)
              #This block is to see if there are SPECIFIC MSH2 and MSH6 records
            elsif clinicomm.scan(MSH2_6).size > 0 && clinicomm !~ NON_LYNCH_REGEX
              msh2_6_specific(raw_genotype, clinicomm, genocolorectal, genotypes)
              #This block is to see if there are NON LYNCH records
            elsif clinicomm.scan(NON_LYNCH_REGEX).size > 0 && clinicomm !~ LYNCH_SPECIFIC \
              && clinicomm !~ LYNCH && clinicomm !~ MSH2_6
              nonlynchgenes(raw_genotype, clinicomm, genocolorectal, genotypes)
              # This block is to see if there are NON LYNCH and BROAD LYNCH records
            elsif clinicomm.scan(NON_LYNCH_REGEX).size > 0 && clinicomm.scan(LYNCH).size > 0 \
            && clinicomm !~ LYNCH_SPECIFIC && clinicomm !~ MSH2_6
              unionlynchgenes(raw_genotype, clinicomm, genocolorectal, genotypes)
            elsif
              @logger.debug "NOTHING TO DO FOR #{clinicomm}"
            end
            genotypes
          end


          def negativegenes(genocolorectal, negativegenes, genotypes )
            negativegenes.each do |genes|
              genocolorectal1 = genocolorectal.dup_colo
              @logger.debug "SUCCESSFUL gene parse for negative test for: #{genes}"
              genocolorectal1.add_status(1)
              genocolorectal1.add_gene_colorectal(genes)
              genocolorectal1.add_protein_impact(nil)
              genocolorectal1.add_gene_location(nil)
              genotypes.append(genocolorectal1)
            end
          end

          def lynchgenes(raw_genotype, _clinicomm, genocolorectal, genotypes)
            lynchgenes = %w[MLH1 MSH2 MSH6 EPCAM]
            if raw_genotype.scan(COLORECTAL_GENES_REGEX).size > 0
              mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
              if raw_genotype.scan(CDNA_REGEX).size > 0 && raw_genotype !~ EXON_REGEX
                mutatedcdna = raw_genotype.scan(CDNA_REGEX).flatten
                mutatedprotein = raw_genotype.scan(PROTEIN_REGEX_COLO).flatten
                mutations = mutatedgene.zip(mutatedcdna, mutatedprotein)
                @logger.debug 'Found BROAD LYNCH dna mutation in ' \
                "#{raw_genotype.scan(COLORECTAL_GENES_REGEX)} LYNCH RELATED GENE(s) in " \
                "position #{raw_genotype.scan(CDNA_REGEX)}" \
                " with impact #{raw_genotype.scan(PROTEIN_REGEX_COLO)}"
                mutations.each do |gene, cdna, protein|
                  mutatedgenotype = genocolorectal.dup_colo
                  @logger.debug 'SUCCESSFUL gene parse for positive test for: ' \
                  "#{gene}, #{cdna}, #{protein}"
                  mutatedgenotype.add_gene_colorectal(gene)
                  mutatedgenotype.add_gene_location(cdna)
                  mutatedgenotype.add_protein_impact(protein)
                  genotypes.append(mutatedgenotype)
                end
                negativegenes = lynchgenes - mutatedgene
                negativegenes(genocolorectal, negativegenes, genotypes)
              elsif EXON_REGEX.match(raw_genotype) && raw_genotype !~ CDNA_REGEX
                @logger.debug "Found LYNCH CHROMOSOME #{EXON_REGEX.match(raw_genotype)[:deldupins]} "\
                "in #{COLORECTAL_GENES_REGEX.match(raw_genotype)[:colorectal]} LYNCH RELATED GENE at "\
                "position #{EXON_REGEX.match(raw_genotype)[:exno]}"
                mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
                negativegenes = lynchgenes - mutatedgene
                negativegenes(genocolorectal, negativegenes, genotypes)
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(raw_genotype)[:colorectal])
                genocolorectal.add_exon_location(EXON_REGEX.match(raw_genotype)[:exno])
                genocolorectal.add_variant_type(EXON_REGEX.match(raw_genotype)[:deldupins])
                genotypes.append(genocolorectal)
              elsif EXON_REGEX.match(raw_genotype) && CDNA_REGEX.match(raw_genotype)
                mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
                negativegenes = lynchgenes - mutatedgene
                negativegenes(genocolorectal, negativegenes, genotypes)
                mutatedexongenotype = genocolorectal.dup_colo
                mutatedexongenotype.add_gene_colorectal(raw_genotype.scan(COLORECTAL_GENES_REGEX)[0].join)
                mutatedexongenotype.add_exon_location(EXON_REGEX.match(raw_genotype)[:exno])
                mutatedexongenotype.add_variant_type(EXON_REGEX.match(raw_genotype)[:deldupins])
                genocolorectal.add_gene_colorectal(raw_genotype.scan(COLORECTAL_GENES_REGEX)[1].join)
                genocolorectal.add_gene_location(CDNA_REGEX.match(raw_genotype)[:dna])
                genocolorectal.add_protein_impact(PROTEIN_REGEX_COLO.match(raw_genotype)[:impact])
                genotypes.append(mutatedexongenotype)
                genotypes.append(genocolorectal)
                # The following long block is for "rogue" genotypes that needed to be
                # Manually extracted. Poor scripting, but quite tight deadlines.
                # Will come back to this as soon as there is some time
              elsif raw_genotype == 'MSH2 c.1760-2_1783del p.(Gly587Aspfs*6)'
                mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
                negativegenes = lynchgenes - mutatedgene
                negativegenes(genocolorectal, negativegenes, genotypes)
                genocolorectal.add_gene_colorectal('MSH2')
                genocolorectal.add_gene_location('1760-2_1783del')
                genocolorectal.add_protein_impact('Gly587Aspfs*')
                genotypes.append(genocolorectal)
              elsif raw_genotype == 'MSH2 del exon11'
                mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
                negativegenes = lynchgenes - mutatedgene
                negativegenes(genocolorectal, negativegenes, genotypes)
                genocolorectal.add_gene_colorectal('MSH2')
                genocolorectal.add_exon_location('11')
                genocolorectal.add_variant_type('del')
                genotypes.append(genocolorectal)
              elsif raw_genotype == "MSH2 ex1-6 duplication"
                mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
                negativegenes = lynchgenes - mutatedgene
                negativegenes(genocolorectal, negativegenes, genotypes)
                genocolorectal.add_gene_colorectal('MSH2')
                genocolorectal.add_exon_location('1-6')
                genocolorectal.add_variant_type('dup')
                genotypes.append(genocolorectal)
              elsif raw_genotype == "MSH2 ex11del"
                mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
                negativegenes = lynchgenes - mutatedgene
                negativegenes(genocolorectal, negativegenes, genotypes)
                genocolorectal.add_gene_colorectal('MSH2')
                genocolorectal.add_exon_location('11')
                genocolorectal.add_variant_type('del')
                genotypes.append(genocolorectal)
              elsif raw_genotype == 'MLH1 c.532delG'
                mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
                negativegenes = lynchgenes - mutatedgene
                negativegenes(genocolorectal, negativegenes, genotypes)
                genocolorectal.add_gene_colorectal('MLH1')
                genocolorectal.add_gene_location('532delG')
                genotypes.append(genocolorectal)
              elsif raw_genotype == 'Deletion including EPCAM ex2-9 and MSH2 ex 1-5'
                mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
                negativegenes = lynchgenes - mutatedgene
                negativegenes(genocolorectal, negativegenes, genotypes)
                genocolorectal2 = genocolorectal.dup_colo
                genocolorectal2.add_gene_colorectal(raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten[0])
                genocolorectal2.add_exon_location('2-9')
                genocolorectal2.add_variant_type('del')
                genotypes.append(genocolorectal2)
                genocolorectal.add_gene_colorectal(raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten[1])
                genocolorectal.add_exon_location('1-5')
                genocolorectal.add_variant_type('del')
                genotypes.append(genocolorectal)
              elsif raw_genotype == "No mutation detected in MLH1"
                mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
                negativegenes = lynchgenes - mutatedgene
                negativegenes(genocolorectal, negativegenes, genotypes)
              elsif raw_genotype == 'MSH2 ex7del'
                mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
                negativegenes = lynchgenes - mutatedgene
                negativegenes(genocolorectal, negativegenes, genotypes)
                genocolorectal.add_gene_colorectal('MSH2')
                genocolorectal.add_exon_location('7')
                genocolorectal.add_variant_type('del')
                genotypes.append(genocolorectal)
              end
            elsif /no mutation|No mutation detected/i.match(raw_genotype)
              @logger.debug 'Found no mutation in broad lynch genes'
              lynchgenes.each do |genes|
                genocolorectal1 = genocolorectal.dup_colo
                @logger.debug "SUCCESSFUL gene parse for negative test for: #{genes}"
                genocolorectal1.add_status(1)
                genocolorectal1.add_gene_colorectal(genes)
                genocolorectal1.add_protein_impact(nil)
                genocolorectal1.add_gene_location(nil)
                genotypes.append(genocolorectal1)
              end
            end
          end

          def lynch_specific(raw_genotype, clinicomm, genocolorectal, genotypes)
            if raw_genotype.scan(COLORECTAL_GENES_REGEX).size > 0
              lynchgenes_spec = clinicomm.scan(COLORECTAL_GENES_REGEX).flatten.map(&:upcase)
              mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
              if raw_genotype.scan(CDNA_REGEX).size > 0 && raw_genotype !~ EXON_REGEX
                mutatedcdna = raw_genotype.scan(CDNA_REGEX).flatten
                mutatedprotein = raw_genotype.scan(PROTEIN_REGEX_COLO).flatten
                mutations = mutatedgene.zip(mutatedcdna, mutatedprotein)
                @logger.debug 'Found SPECIFIC LYNCH dna mutation in ' \
                "#{raw_genotype.scan(COLORECTAL_GENES_REGEX)} LYNCH RELATED GENE(s) in "\
                "position #{raw_genotype.scan(CDNA_REGEX)}" \
                " with impact #{raw_genotype.scan(PROTEIN_REGEX_COLO)}"
                mutations.each do |gene, cdna, protein|
                  mutatedgenotype = genocolorectal.dup_colo
                  @logger.debug 'SUCCESSFUL gene parse for positive test for: ' \
                  "#{gene}, #{cdna}, #{protein}"
                  mutatedgenotype.add_gene_colorectal(gene)
                  mutatedgenotype.add_gene_location(cdna)
                  mutatedgenotype.add_protein_impact(protein)
                  genotypes.append(mutatedgenotype)
                end
                negativegenes =  lynchgenes_spec - mutatedgene
                negativegenes.each do |genes|
                  genocolorectal1 = genocolorectal.dup_colo
                  @logger.debug 'SUCCESSFUL gene parse for NEGATIVE test IN ' \
                  "LYNCH SPECIFIC for: #{genes}"
                  genocolorectal1.add_status(1)
                  genocolorectal1.add_gene_colorectal(genes)
                  genocolorectal1.add_protein_impact(nil)
                  genocolorectal1.add_gene_location(nil)
                  genotypes.append(genocolorectal1)
                end
              elsif EXON_REGEX.match(raw_genotype) && raw_genotype !~ CDNA_REGEX
                @logger.debug 'Found LYNCH_SPEC' \
                "#{EXON_REGEX.match(raw_genotype)[:deldupins]} "\
                "in #{COLORECTAL_GENES_REGEX.match(raw_genotype)[:colorectal]} " \
                'LYNCH RELATED GENE at ' \
                "position #{EXON_REGEX.match(raw_genotype)[:exno]}"
                mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
                lynchgenes_spec = clinicomm.scan(COLORECTAL_GENES_REGEX).flatten.map(&:upcase)
                negativegenes = lynchgenes_spec - mutatedgene
                negativegenes(genocolorectal, negativegenes, genotypes)
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(raw_genotype)[:colorectal])
                genocolorectal.add_exon_location(EXON_REGEX.match(raw_genotype)[:exno])
                genocolorectal.add_variant_type(EXON_REGEX.match(raw_genotype)[:deldupins])
                genotypes.append(genocolorectal)
              elsif EXON_REGEX.match(raw_genotype) && CDNA_REGEX.match(raw_genotype)
                @logger.debug "Found LYNCH_SPEC #{EXON_REGEX.match(raw_genotype)[:deldupins]} "\
                "in #{raw_genotype.scan(COLORECTAL_GENES_REGEX)[0]} LYNCH RELATED GENE at "\
                "position #{EXON_REGEX.match(raw_genotype)[:exno]} and " \
                "Mutation #{CDNA_REGEX.match(raw_genotype)[:dna]} in gene "\
                "#{raw_genotype.scan(COLORECTAL_GENES_REGEX)[0]} at " \
                "position #{raw_genotype.scan(CDNA_REGEX)}" \
                " with impact #{raw_genotype.scan(PROTEIN_REGEX_COLO)}"
                mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
                lynchgenes_spec = clinicomm.scan(COLORECTAL_GENES_REGEX).flatten.map(&:upcase)
                negativegenes = lynchgenes_spec - mutatedgene
                negativegenes(genocolorectal, negativegenes, genotypes)
                mutatedexongenotype = genocolorectal.dup_colo
                mutatedexongenotype.add_gene_colorectal(raw_genotype.scan(COLORECTAL_GENES_REGEX)[0].join)
                mutatedexongenotype.add_exon_location(EXON_REGEX.match(raw_genotype)[:exno])
                mutatedexongenotype.add_variant_type(EXON_REGEX.match(raw_genotype)[:deldupins])
                genocolorectal.add_gene_colorectal(raw_genotype.scan(COLORECTAL_GENES_REGEX)[1].join)
                genocolorectal.add_gene_location(CDNA_REGEX.match(raw_genotype)[:dna])
                genocolorectal.add_protein_impact(PROTEIN_REGEX_COLO.match(raw_genotype)[:impact])
                genotypes.append(mutatedexongenotype)
                genotypes.append(genocolorectal)
              end
            elsif /no mutation|No mutation detected/i.match(raw_genotype)
              lynchgenes_spec = clinicomm.scan(COLORECTAL_GENES_REGEX).flatten.map(&:upcase)
              @logger.debug 'Found no mutation in lynch specific genes' \
              'Genes LYNCH SPECIFIC ' \
              "#{clinicomm.scan(COLORECTAL_GENES_REGEX).flatten.map(&:upcase)} are normal"
              lynchgenes_spec.each do |genes|
                genocolorectal1 = genocolorectal.dup_colo
                @logger.debug "SUCCESSFUL gene parse for negative test for: #{genes}"
                genocolorectal1.add_status(1)
                genocolorectal1.add_gene_colorectal(genes)
                genocolorectal1.add_protein_impact(nil)
                genocolorectal1.add_gene_location(nil)
                genotypes.append(genocolorectal1)
              end
            end
          end

          def msh2_6_specific(raw_genotype, _clinicomm, genocolorectal, genotypes)
            if raw_genotype.scan(COLORECTAL_GENES_REGEX).size > 0
              mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
              if raw_genotype.scan(CDNA_REGEX).size > 0 && raw_genotype !~ EXON_REGEX
                mutatedcdna = raw_genotype.scan(CDNA_REGEX).flatten
                mutatedprotein = raw_genotype.scan(PROTEIN_REGEX_COLO).flatten
                mutations = mutatedgene.zip(mutatedcdna, mutatedprotein)
                @logger.debug 'Found SPECIFIC LYNCH dna mutation in ' \
                "#{raw_genotype.scan(COLORECTAL_GENES_REGEX)} LYNCH SPECIFIC GENE(s) in "\
                "position #{raw_genotype.scan(CDNA_REGEX)}" \
                " with impact #{raw_genotype.scan(PROTEIN_REGEX_COLO)}"
                mutations.each do |gene, cdna, protein|
                  mutatedgenotype = genocolorectal.dup_colo
                  @logger.debug 'SUCCESSFUL gene parse for positive test for: '\
                  "#{gene}, #{cdna}, #{protein}"
                  mutatedgenotype.add_gene_colorectal(gene)
                  mutatedgenotype.add_gene_location(cdna)
                  mutatedgenotype.add_protein_impact(protein)
                  genotypes.append(mutatedgenotype)
                end
                negativegenes = %w[MSH2 MSH6] - mutatedgene
                negativegenes(genocolorectal, negativegenes, genotypes)
              elsif EXON_REGEX.match(raw_genotype) && raw_genotype !~ CDNA_REGEX
                @logger.debug 'Found LYNCH CHROMOSOME ' \
                "#{EXON_REGEX.match(raw_genotype)[:deldupins]} " \
                "in #{COLORECTAL_GENES_REGEX.match(raw_genotype)[:colorectal]} " \
                'LYNCH SPECIFIC GENE at '\
                "position #{EXON_REGEX.match(raw_genotype)[:exno]}"
                mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
                negativegenes = %w[MSH2 MSH6] - mutatedgene
                negativegenes(genocolorectal, negativegenes, genotypes)
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(raw_genotype)[:colorectal])
                genocolorectal.add_exon_location(EXON_REGEX.match(raw_genotype)[:exno])
                genocolorectal.add_variant_type(EXON_REGEX.match(raw_genotype)[:deldupins])
                genotypes.append(genocolorectal)
              elsif EXON_REGEX.match(raw_genotype) && CDNA_REGEX.match(raw_genotype)
                mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
                negativegenes = %w[MSH2 MSH6] - mutatedgene
                negativegenes(genocolorectal, negativegenes, genotypes)
                mutatedexongenotype = genocolorectal.dup_colo
                mutatedexongenotype.add_gene_colorectal(raw_genotype.scan(COLORECTAL_GENES_REGEX)[0].join)
                mutatedexongenotype.add_exon_location(EXON_REGEX.match(raw_genotype)[:exno])
                mutatedexongenotype.add_variant_type(EXON_REGEX.match(raw_genotype)[:deldupins])
                genocolorectal.add_gene_colorectal(raw_genotype.scan(COLORECTAL_GENES_REGEX)[1].join)
                genocolorectal.add_gene_location(CDNA_REGEX.match(raw_genotype)[:dna])
                genocolorectal.add_protein_impact(PROTEIN_REGEX_COLO.match(raw_genotype)[:impact])
                genotypes.append(mutatedexongenotype)
                genotypes.append(genocolorectal)
              end
            elsif /no mutation|No mutation detected/i.match(raw_genotype)
              @logger.debug 'Found no mutation in MSH2/MSH6 lynch genes'
              %w[MSH2 MSH6].each do |genes|
                genocolorectal1 = genocolorectal.dup_colo
                @logger.debug "SUCCESSFUL gene parse for negative test for: #{genes}"
                genocolorectal1.add_status(1)
                genocolorectal1.add_gene_colorectal(genes)
                genocolorectal1.add_protein_impact(nil)
                genocolorectal1.add_gene_location(nil)
                genotypes.append(genocolorectal1)
              end
            end
          end

          def nonlynchgenes(raw_genotype, clinicomm, genocolorectal, genotypes)
            if raw_genotype == 'No mutation detected' \
              && clinicomm == 'Familial Adenomatous Polyposis;MUTYH-associated Polyposis;Trusight Cancer panel;pole/pold1 testing'
              %w[APC MUTYH POLD1 POLE].each do |genes|
                genocolorectal1 = genocolorectal.dup_colo
                @logger.debug "SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: #{genes}"
                genocolorectal1.add_status(1)
                genocolorectal1.add_gene_colorectal(genes)
                genocolorectal1.add_protein_impact(nil)
                genocolorectal1.add_gene_location(nil)
                genotypes.append(genocolorectal1)
              end
            elsif raw_genotype == 'No mutation detected' \
              && clinicomm == 'Trusight Cancer panel; familial adenomatous polyposis; MAP'
              %w[APC MUTYH].each do |genes|
                genocolorectal1 = genocolorectal.dup_colo
                @logger.debug "SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: #{genes}"
                genocolorectal1.add_status(1)
                genocolorectal1.add_gene_colorectal(genes)
                genocolorectal1.add_protein_impact(nil)
                genocolorectal1.add_gene_location(nil)
                genotypes.append(genocolorectal1)
              end
            elsif raw_genotype.scan(COLORECTAL_GENES_REGEX).size > 0
              mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
              if raw_genotype.scan(CDNA_REGEX).size > 0 && raw_genotype !~ EXON_REGEX
                mutatedcdna = raw_genotype.scan(CDNA_REGEX).flatten
                mutatedprotein = raw_genotype.scan(PROTEIN_REGEX_COLO).flatten
                mutations = mutatedgene.zip(mutatedcdna, mutatedprotein)
                @logger.debug 'Found NON-LYNCH dna mutation in ' \
                "#{mutatedgene} LYNCH RELATED GENE(s) in "\
                "position #{raw_genotype.scan(CDNA_REGEX)}" \
                " with impact #{raw_genotype.scan(PROTEIN_REGEX_COLO)}"
                mutations.each do |gene, cdna, protein|
                  mutatedgenotype = genocolorectal.dup_colo
                  @logger.debug 'SUCCESSFUL gene parse for positive test for: '\
                  "#{gene}, #{cdna}, #{protein}"
                  mutatedgenotype.add_gene_colorectal(gene)
                  mutatedgenotype.add_gene_location(cdna)
                  mutatedgenotype.add_protein_impact(protein)
                  genotypes.append(mutatedgenotype)
                end
                nonlynchgenes = []
                clinicomm.scan(NON_LYNCH_REGEX).each \
                { |x| nonlynchgenes.append(NON_LYNCH_MAP[x]) }
                negativegenes = nonlynchgenes.flatten.uniq - mutatedgene
                if negativegenes.any?
                  @logger.debug 'SUCCESSFUL gene parse for NEGATIVE test IN ' \
                  "NON LYNCH for: #{negativegenes.flatten.uniq}"
                  negativegenes.flatten.uniq.each do |genes|
                    genocolorectal1 = genocolorectal.dup_colo
                    @logger.debug 'SUCCESSFUL gene parse for NEGATIVE test IN ' \
                    "NON LYNCH for: #{genes}"
                    genocolorectal1.add_status(1)
                    genocolorectal1.add_gene_colorectal(genes)
                    genocolorectal1.add_protein_impact(nil)
                    genocolorectal1.add_gene_location(nil)
                    genotypes.append(genocolorectal1)
                  end
                end
              elsif EXON_REGEX.match(raw_genotype) && raw_genotype !~ CDNA_REGEX
                @logger.debug 'Found NON-LYNCH CHROMOSOME ' \
                "#{EXON_REGEX.match(raw_genotype)[:deldupins]} "\
                "in #{COLORECTAL_GENES_REGEX.match(raw_genotype)[:colorectal]} " \
                'NON-LYNCH GENE at '\
                "position #{EXON_REGEX.match(raw_genotype)[:exno]}"
                mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
                nonlynchgenes = []
                clinicomm.scan(NON_LYNCH_REGEX).each \
                { |x| nonlynchgenes.append(NON_LYNCH_MAP[x]) }
                negativegenes = nonlynchgenes.flatten.uniq - mutatedgene
                if negativegenes.any?
                  @logger.debug 'SUCCESSFUL gene parse for NEGATIVE test IN ' \
                  "NON LYNCH for: #{negativegenes.flatten}"
                  negativegenes.flatten.uniq.each do |genes|
                    genocolorectal1 = genocolorectal.dup_colo
                    @logger.debug 'SUCCESSFUL gene parse for NEGATIVE test IN ' \
                    "NON LYNCH for: #{genes}"
                    genocolorectal1.add_status(1)
                    genocolorectal1.add_gene_colorectal(genes)
                    genocolorectal1.add_protein_impact(nil)
                    genocolorectal1.add_gene_location(nil)
                    genotypes.append(genocolorectal1)
                  end
                end
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(raw_genotype)[:colorectal])
                genocolorectal.add_exon_location(EXON_REGEX.match(raw_genotype)[:exno])
                genocolorectal.add_variant_type(EXON_REGEX.match(raw_genotype)[:deldupins])
                genotypes.append(genocolorectal)
              elsif EXON_REGEX.match(raw_genotype) && CDNA_REGEX.match(raw_genotype)
                mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
                nonlynchgenes = []
                clinicomm.scan(NON_LYNCH_REGEX).each \
                { |x| nonlynchgenes.append(NON_LYNCH_MAP[x]) }
                negativegenes = nonlynchgenes.flatten.uniq - mutatedgene
                if negativegenes.any?
                  @logger.debug 'SUCCESSFUL gene parse for NEGATIVE test IN ' \
                  "NON LYNCH for: #{negativegenes.flatten}"
                  negativegenes.flatten.uniq.each do |genes|
                    genocolorectal1 = genocolorectal.dup_colo
                    @logger.debug 'SUCCESSFUL gene parse for NEGATIVE test IN ' \
                    "NON LYNCH for: #{genes}"
                    genocolorectal1.add_status(1)
                    genocolorectal1.add_gene_colorectal(genes)
                    genocolorectal1.add_protein_impact(nil)
                    genocolorectal1.add_gene_location(nil)
                    genotypes.append(genocolorectal1)
                  end
                end
                mutatedexongenotype = genocolorectal.dup_colo
                mutatedexongenotype.add_gene_colorectal(raw_genotype.scan(COLORECTAL_GENES_REGEX)[0].join)
                mutatedexongenotype.add_exon_location(EXON_REGEX.match(raw_genotype)[:exno])
                mutatedexongenotype.add_variant_type(EXON_REGEX.match(raw_genotype)[:deldupins])
                genocolorectal.add_gene_colorectal(raw_genotype.scan(COLORECTAL_GENES_REGEX)[1].join)
                genocolorectal.add_gene_location(CDNA_REGEX.match(raw_genotype)[:dna])
                genocolorectal.add_protein_impact(PROTEIN_REGEX_COLO.match(raw_genotype)[:impact])
                genotypes.append(mutatedexongenotype)
                genotypes.append(genocolorectal)
                # Rogue genotypes block
              elsif raw_genotype == 'APC promoter 1B deletion (single probe)'
                mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
                nonlynchgenes = []
                clinicomm.scan(NON_LYNCH_REGEX).each \
                { |x| nonlynchgenes.append(NON_LYNCH_MAP[x]) }
                negativegenes = nonlynchgenes.flatten.uniq - mutatedgene
                if negativegenes.any?
                  @logger.debug 'SUCCESSFUL gene parse for NEGATIVE test IN ' \
                  "NON LYNCH for: #{negativegenes.flatten}"
                  negativegenes.flatten.uniq.each do |genes|
                    genocolorectal1 = genocolorectal.dup_colo
                    @logger.debug 'SUCCESSFUL gene parse for NEGATIVE test IN ' \
                    "NON LYNCH for: #{genes}"
                    genocolorectal1.add_status(1)
                    genocolorectal1.add_gene_colorectal(genes)
                    genocolorectal1.add_protein_impact(nil)
                    genocolorectal1.add_gene_location(nil)
                    genotypes.append(genocolorectal1)
                  end
                end
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(raw_genotype)[:colorectal])
                genocolorectal.add_variant_type('del')
                genotypes.append(genocolorectal)
              elsif raw_genotype == 'APC c.423-34_423-17delinsA'
                mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
                nonlynchgenes = []
                clinicomm.scan(NON_LYNCH_REGEX).each \
                { |x| nonlynchgenes.append(NON_LYNCH_MAP[x]) }
                negativegenes = nonlynchgenes.flatten.uniq - mutatedgene
                if negativegenes.any?
                  @logger.debug 'SUCCESSFUL gene parse for NEGATIVE test IN ' \
                  "NON LYNCH for: #{negativegenes.flatten}"
                  negativegenes.flatten.uniq.each do |genes|
                    genocolorectal1 = genocolorectal.dup_colo
                    @logger.debug 'SUCCESSFUL gene parse for NEGATIVE test IN ' \
                    "NON LYNCH for: #{genes}"
                    genocolorectal1.add_status(1)
                    genocolorectal1.add_gene_colorectal(genes)
                    genocolorectal1.add_protein_impact(nil)
                    genocolorectal1.add_gene_location(nil)
                    genotypes.append(genocolorectal1)
                  end
                end
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(raw_genotype)[:colorectal])
                genocolorectal.add_gene_location('423-34_423-17delinsA')
                genotypes.append(genocolorectal)
              elsif raw_genotype == 'APC ex10-18del'
                mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
                nonlynchgenes = []
                clinicomm.scan(NON_LYNCH_REGEX).each \
                { |x| nonlynchgenes.append(NON_LYNCH_MAP[x]) }
                negativegenes = nonlynchgenes.flatten.uniq - mutatedgene
                if negativegenes.any?
                  @logger.debug 'SUCCESSFUL gene parse for NEGATIVE test IN ' \
                  "NON LYNCH for: #{negativegenes.flatten}"
                  negativegenes.flatten.uniq.each do |genes|
                    genocolorectal1 = genocolorectal.dup_colo
                    @logger.debug 'SUCCESSFUL gene parse for NEGATIVE test IN ' \
                    "NON LYNCH for: #{genes}"
                    genocolorectal1.add_status(1)
                    genocolorectal1.add_gene_colorectal(genes)
                    genocolorectal1.add_protein_impact(nil)
                    genocolorectal1.add_gene_location(nil)
                    genotypes.append(genocolorectal1)
                  end
                end
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(raw_genotype)[:colorectal])
                genocolorectal.add_exon_location('10-18')
                genocolorectal.add_variant_type('del')
                genotypes.append(genocolorectal)
              elsif raw_genotype == 'MUTYH p.Glu480* homozygote'
                mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
                nonlynchgenes = []
                clinicomm.scan(NON_LYNCH_REGEX).each \
                { |x| nonlynchgenes.append(NON_LYNCH_MAP[x]) }
                negativegenes = nonlynchgenes.flatten.uniq - mutatedgene
                if negativegenes.any?
                  @logger.debug 'SUCCESSFUL gene parse for NEGATIVE test IN ' \
                  "NON LYNCH for: #{negativegenes.flatten}"
                  negativegenes.flatten.uniq.each do |genes|
                    genocolorectal1 = genocolorectal.dup_colo
                    @logger.debug 'SUCCESSFUL gene parse for NEGATIVE test IN' \
                    " NON LYNCH for: #{genes}"
                    genocolorectal1.add_status(1)
                    genocolorectal1.add_gene_colorectal(genes)
                    genocolorectal1.add_protein_impact(nil)
                    genocolorectal1.add_gene_location(nil)
                    genotypes.append(genocolorectal1)
                  end
                end
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(raw_genotype)[:colorectal])
                genocolorectal.add_protein_impact('Glu480*')
                genotypes.append(genocolorectal)
              elsif raw_genotype == 'STK11 ex1-10del'
                mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
                nonlynchgenes = []
                clinicomm.scan(NON_LYNCH_REGEX).each \
                { |x| nonlynchgenes.append(NON_LYNCH_MAP[x]) }
                negativegenes = nonlynchgenes.flatten.uniq - mutatedgene
                if negativegenes.any?
                  @logger.debug 'SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH' \
                  "for: #{negativegenes.flatten}"
                  negativegenes.flatten.uniq.each do |genes|
                    genocolorectal1 = genocolorectal.dup_colo
                    @logger.debug 'SUCCESSFUL gene parse for NEGATIVE test IN ' \
                    "NON LYNCH for: #{genes}"
                    genocolorectal1.add_status(1)
                    genocolorectal1.add_gene_colorectal(genes)
                    genocolorectal1.add_protein_impact(nil)
                    genocolorectal1.add_gene_location(nil)
                    genotypes.append(genocolorectal1)
                  end
                end
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(raw_genotype)[:colorectal])
                genocolorectal.add_exon_location('1-10')
                genocolorectal.add_variant_type('del')
                genotypes.append(genocolorectal)
              end
            elsif /no mutation|No mutation detected|Normal result/i.match(raw_genotype)
              nonlynchgenes = []
              clinicomm.scan(NON_LYNCH_REGEX).each \
              { |x| nonlynchgenes.append(NON_LYNCH_MAP[x]) }
              @logger.debug "Found no mutation; Genes #{nonlynchgenes.flatten.uniq} are normal"
              nonlynchgenes.flatten.uniq.each do |genes|
                genocolorectal1 = genocolorectal.dup_colo
                @logger.debug "SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: #{genes}"
                genocolorectal1.add_status(1)
                genocolorectal1.add_gene_colorectal(genes)
                genocolorectal1.add_protein_impact(nil)
                genocolorectal1.add_gene_location(nil)
                genotypes.append(genocolorectal1)
              end
            end
          end

          def unionlynchgenes(raw_genotype, clinicomm, genocolorectal, genotypes)
            lynchgenes = %w[MLH1 MSH2 MSH6 EPCAM]
            @logger.debug 'Found NON_LYNCH and LYNCH test'
            if raw_genotype.scan(COLORECTAL_GENES_REGEX).size > 0
              mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
              if raw_genotype.scan(CDNA_REGEX).size > 0 && raw_genotype !~ EXON_REGEX
                mutatedcdna = raw_genotype.scan(CDNA_REGEX).flatten
                mutatedprotein = raw_genotype.scan(PROTEIN_REGEX_COLO).flatten
                mutations = mutatedgene.zip(mutatedcdna, mutatedprotein)
                @logger.debug 'Found BROAD LYNCH dna mutation in ' \
                "#{raw_genotype.scan(COLORECTAL_GENES_REGEX)} LYNCH and " \
                'NON-LYNCH RELATED GENE(s) in '\
                "position #{raw_genotype.scan(CDNA_REGEX)}" \
                " with impact #{raw_genotype.scan(PROTEIN_REGEX_COLO)}"
                mutations.each do |gene, cdna, protein|
                  mutatedgenotype = genocolorectal.dup_colo
                  @logger.debug 'SUCCESSFUL gene parse for positive test for: '\
                  "#{gene}, #{cdna}, #{protein}"
                  mutatedgenotype.add_gene_colorectal(gene)
                  mutatedgenotype.add_gene_location(cdna)
                  mutatedgenotype.add_protein_impact(protein)
                  genotypes.append(mutatedgenotype)
                end
                nonlynchgenes = []
                clinicomm.scan(NON_LYNCH_REGEX).each \
                { |x| nonlynchgenes.append(NON_LYNCH_MAP[x]) }
                uniongenes = lynchgenes + nonlynchgenes.flatten
                negativegenes = uniongenes.uniq - mutatedgene
                if negativegenes.any?
                  @logger.debug 'SUCCESSFUL gene parse for NEGATIVE test in LYNCH AND NON-LYNCH' \
                  " for: #{negativegenes.flatten.uniq}"
                  negativegenes.flatten.uniq.each do |genes|
                    genocolorectal1 = genocolorectal.dup_colo
                    @logger.debug 'SUCCESSFUL gene parse for NEGATIVE test in LYNCH' \
                    "AND NON-LYNCH for: #{genes}"
                    genocolorectal1.add_status(1)
                    genocolorectal1.add_gene_colorectal(genes)
                    genocolorectal1.add_protein_impact(nil)
                    genocolorectal1.add_gene_location(nil)
                    genotypes.append(genocolorectal1)
                  end
                end
              elsif EXON_REGEX.match(raw_genotype) && raw_genotype !~ CDNA_REGEX
                @logger.debug 'Found LYNCH CHROMOSOME' \
                "#{EXON_REGEX.match(raw_genotype)[:deldupins]} "\
                "in #{COLORECTAL_GENES_REGEX.match(raw_genotype)[:colorectal]} LYNCH and " \
                'NON-LYNCH RELATED GENE(s) at '\
                "position #{EXON_REGEX.match(raw_genotype)[:exno]}"
                mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
                nonlynchgenes = []
                clinicomm.scan(NON_LYNCH_REGEX).each \
                { |x| nonlynchgenes.append(NON_LYNCH_MAP[x]) }
                uniongenes = lynchgenes + nonlynchgenes.flatten
                negativegenes = uniongenes.uniq - mutatedgene
                if negativegenes.any?
                  @logger.debug 'SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: ' \
                  "#{negativegenes.flatten.uniq}"
                  negativegenes.flatten.uniq.each do |genes|
                    genocolorectal1 = genocolorectal.dup_colo
                    @logger.debug 'SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: ' \
                    "#{genes}"
                    genocolorectal1.add_status(1)
                    genocolorectal1.add_gene_colorectal(genes)
                    genocolorectal1.add_protein_impact(nil)
                    genocolorectal1.add_gene_location(nil)
                    genotypes.append(genocolorectal1)
                  end
                end
                genocolorectal.add_gene_colorectal(COLORECTAL_GENES_REGEX.match(raw_genotype)[:colorectal])
                genocolorectal.add_exon_location(EXON_REGEX.match(raw_genotype)[:exno])
                genocolorectal.add_variant_type(EXON_REGEX.match(raw_genotype)[:deldupins])
                genotypes.append(genocolorectal)
              elsif EXON_REGEX.match(raw_genotype) && CDNA_REGEX.match(raw_genotype)
                mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
                nonlynchgenes = []
                clinicomm.scan(NON_LYNCH_REGEX).each \
                { |x| nonlynchgenes.append(NON_LYNCH_MAP[x]) }
                uniongenes = lynchgenes + nonlynchgenes.flatten
                negativegenes = uniongenes.uniq - mutatedgene
                if negativegenes.any?
                  @logger.debug 'SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: ' \
                  "#{negativegenes.flatten.uniq}"
                  negativegenes.flatten.uniq.each do |genes|
                    genocolorectal1 = genocolorectal.dup_colo
                    @logger.debug 'SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: ' \
                    "#{genes}"
                    genocolorectal1.add_status(1)
                    genocolorectal1.add_gene_colorectal(genes)
                    genocolorectal1.add_protein_impact(nil)
                    genocolorectal1.add_gene_location(nil)
                    genotypes.append(genocolorectal1)
                  end
                end
                mutatedexongenotype = genocolorectal.dup_colo
                mutatedexongenotype.add_gene_colorectal(raw_genotype.scan(COLORECTAL_GENES_REGEX)[0].join)
                mutatedexongenotype.add_exon_location(EXON_REGEX.match(raw_genotype)[:exno])
                mutatedexongenotype.add_variant_type(EXON_REGEX.match(raw_genotype)[:deldupins])
                genocolorectal.add_gene_colorectal(raw_genotype.scan(COLORECTAL_GENES_REGEX)[1].join)
                genocolorectal.add_gene_location(CDNA_REGEX.match(raw_genotype)[:dna])
                genocolorectal.add_protein_impact(PROTEIN_REGEX_COLO.match(raw_genotype)[:impact])
                genotypes.append(mutatedexongenotype)
                genotypes.append(genocolorectal)
              elsif raw_genotype == 'BMPR1A: c.972dupT'
                mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
                nonlynchgenes = []
                clinicomm.scan(NON_LYNCH_REGEX).each \
                { |x| nonlynchgenes.append(NON_LYNCH_MAP[x]) }
                uniongenes = lynchgenes + nonlynchgenes.flatten
                negativegenes = uniongenes.uniq - mutatedgene
                if negativegenes.any?
                  @logger.debug 'SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: ' \
                  "#{negativegenes.flatten.uniq}"
                  negativegenes.flatten.uniq.each do |genes|
                    genocolorectal1 = genocolorectal.dup_colo
                    @logger.debug 'SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: ' \
                    "#{genes}"
                    genocolorectal1.add_status(1)
                    genocolorectal1.add_gene_colorectal(genes)
                    genocolorectal1.add_protein_impact(nil)
                    genocolorectal1.add_gene_location(nil)
                    genotypes.append(genocolorectal1)
                  end
                end
                genocolorectal.add_gene_colorectal('BMPR1A')
                genocolorectal.add_gene_location('972dupT')
                genotypes.append(genocolorectal)
              elsif raw_genotype == 'APC c.1880dupA'
                mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
                nonlynchgenes = []
                clinicomm.scan(NON_LYNCH_REGEX).each \
                { |x| nonlynchgenes.append(NON_LYNCH_MAP[x]) }
                uniongenes = lynchgenes + nonlynchgenes.flatten
                negativegenes = uniongenes.uniq - mutatedgene
                if negativegenes.any?
                  @logger.debug 'SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: ' \
                  "#{negativegenes.flatten.uniq}"
                  negativegenes.flatten.uniq.each do |genes|
                    genocolorectal1 = genocolorectal.dup_colo
                    @logger.debug 'SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: ' \
                    "#{genes}"
                    genocolorectal1.add_status(1)
                    genocolorectal1.add_gene_colorectal(genes)
                    genocolorectal1.add_protein_impact(nil)
                    genocolorectal1.add_gene_location(nil)
                    genotypes.append(genocolorectal1)
                  end
                end
                genocolorectal.add_gene_colorectal('APC')
                genocolorectal.add_gene_location('1880dupA')
                genotypes.append(genocolorectal)
              elsif raw_genotype == 'MSH6 c.*24_28del'
                mutatedgene = raw_genotype.scan(COLORECTAL_GENES_REGEX).flatten
                nonlynchgenes = []
                clinicomm.scan(NON_LYNCH_REGEX).each \
                { |x| nonlynchgenes.append(NON_LYNCH_MAP[x]) }
                uniongenes = lynchgenes + nonlynchgenes.flatten
                negativegenes = uniongenes.uniq - mutatedgene
                if negativegenes.any?
                  @logger.debug 'SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: '\
                  "#{negativegenes.flatten.uniq}"
                  negativegenes.flatten.uniq.each do |genes|
                    genocolorectal1 = genocolorectal.dup_colo
                    @logger.debug 'SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for:' \
                    "#{genes}"
                    genocolorectal1.add_status(1)
                    genocolorectal1.add_gene_colorectal(genes)
                    genocolorectal1.add_protein_impact(nil)
                    genocolorectal1.add_gene_location(nil)
                    genotypes.append(genocolorectal1)
                  end
                end
                genocolorectal.add_gene_colorectal('MSH6')
                genocolorectal.add_gene_location('*24_28del')
                genotypes.append(genocolorectal)
              end
            elsif /no mutation|No mutation detected/i.match(raw_genotype)
              lynchgenes = %w[MLH1 MSH2 MSH6 EPCAM]
              nonlynchgenes = []
              clinicomm.scan(NON_LYNCH_REGEX).each \
              { |x| nonlynchgenes.append(NON_LYNCH_MAP[x]) }
              uniongenes = lynchgenes + nonlynchgenes
              @logger.debug "Found no mutation; Genes #{uniongenes.flatten.uniq} are normal"
              uniongenes.flatten.uniq.each do |genes|
                genocolorectal1 = genocolorectal.dup_colo
                @logger.debug "SUCCESSFUL gene parse for NEGATIVE test IN NON LYNCH for: #{genes}"
                genocolorectal1.add_status(1)
                genocolorectal1.add_gene_colorectal(genes)
                genocolorectal1.add_protein_impact(nil)
                genocolorectal1.add_gene_location(nil)
                genotypes.append(genocolorectal1)
              end
            end
          end
        end
      end
    end
  end
end
