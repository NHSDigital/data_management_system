module Export
  module Helpers
    # Mixin to dump schema for Births / Deaths
    # Assumes @e_type, @col_fields, #table_mapping and #header_rows are defined
    module SchemaDump
      extend ActiveSupport::Concern

      # rubocop:disable Style/WordArray
      # Extracted from columns G-J of
      # "doc/spec/MBIS2016 Common Dataset for Deaths description of variables v6.0.xlsx"
      # passed through: $ sed -e "s/\t/', '/g" -e "s/^/        ['/" -e "s/$/'],/"
      DEATH_SPEC_FIELDS = [
        ['Field Label', 'Length', 'Occurrences', 'Data Type'],
        ['MBISM204ID', '15', '1', 'Alphanumeric'],
        ['LEDRID', '13', '1', 'Numeric'],
        ['CESTRSSR', '5', '1', 'Alphanumeric'],
        ['CESTSTAY', '1', '1', 'Alphanumeric'],
        ['CCGPOD', '3', '1', 'Alphanumeric'],
        ['CESTRSS', '5', '1', 'Alphanumeric'],
        ['COD10R_1 to COD10R_20', '2', '20', 'Numeric'],
        ['COD10RF_1 to COD10RF_20', '2', '20', 'Numeric'],
        ['CODT_1 to CODT_5', '75', '5', 'Alphanumeric'],
        ['CTYDPOD', '2', '1', 'Numeric'],
        ['CTYPOD', '2', '1', 'Numeric'],
        ['DESTER', '100', '1', 'Alphanumeric'],
        ['DODDY', '2', '1', 'Numeric'],
        ['DODMT', '2', '1', 'Numeric'],
        ['DODYR', '4', '1', 'Numeric'],
        ['ESTTYPED', '2', '1', 'Alphanumeric'],
        ['HAUTPOD', '3', '1', 'Alphanumeric'],
        ['HROPOD', '3', '1', 'Alphanumeric'],
        ['ICD_1 to ICD_20', '5', '20', 'Alphanumeric'],
        ['ICDF_1 to ICDF_20', '5', '20', 'Alphanumeric'],
        ['ICDPV_1 to ICDPV_20', '5', '20', 'Alphanumeric'],
        ['ICDPVF_1 to ICDPVF_20', '5', '20', 'Alphanumeric'],
        ['ICDSC', '5', '1', 'Alphanumeric'],
        ['ICDSCF', '5', '1', 'Alphanumeric'],
        ['ICDU', '5', '1', 'Alphanumeric'],
        ['ICDUF', '5', '1', 'Alphanumeric'],
        ['ICDFuture1', '5', '1', 'Alphanumeric'],
        ['ICDFuture1', '5', '1', 'Alphanumeric'],
        ['LINENO9_1 - LINENO9_20 LNENO10_1 - LNENO10_20', '2', '20', 'Numeric'],
        ['LINENO9F_1 - LINENO9F_20 LNENO10F_1 - LNENO10F_20', '??', '20', 'Numeric'],
        ['LOAPOD', '9', '1', 'Alphanumeric'],
        ['LSOAPOD', '9', '1', 'Alphanumeric'],
        ['NHSIND', '2', '1', 'Alphanumeric'],
        ['PCDPOD', '8', '1', 'Alphanumeric'],
        ['PLOACC10', '1', '1', 'Numeric'],
        ['PODQUAL', '1', '1', 'Alphanumeric'],
        ['PODT', '100', '1', 'Alphanumeric'],
        ['WIGWO10', '2', '1', 'Alphanumeric'],
        ['WIGWO10F', '2', '1', 'Alphanumeric'],
        ['ADDRDT', '200', '1', 'Alphanumeric'],
        ['AGEC', '3', '1', 'Numeric'],
        ['AGECUNIT', '1', '1', 'Numeric'],
        ['AGEU1D', '10', '1', 'Alphanumeric'],
        ['AKSNAMD', '50', '5', 'Alphanumeric'],
        ['AKFNAMD_1 ', '20', '5', 'Alphanumeric'],
        ['AKFNAMD_2', '20', '5', 'Alphanumeric'],
        ['AKFNAMD_3 ', '20', '5', 'Alphanumeric'],
        ['AKFNDI', '1', '5', 'Alphanumeric'],
        ['ALIASD', '75', '2', 'Alphanumeric'],
        ['CCGR', '3', '1', 'Alphanumeric'],
        ['CTRYPOB', '3', '1', 'Numeric'],
        ['CTRYR', '4', '1', 'Numeric'],
        ['CTYDR', '2', '1', 'Numeric'],
        ['CTYR', '2', '1', 'Numeric'],
        ['DOBDY', '2', '1', 'Numeric'],
        ['DOBMT', '2', '1', 'Numeric'],
        ['DOBYR', '4', '1', 'Numeric'],
        ['FNAMD1', '20', '1', 'Alphanumeric'],
        ['FNAMD2', '20', '1', 'Alphanumeric'],
        ['FNAMD3', '20', '1', 'Alphanumeric'],
        ['FNAMDX', '75', '2', 'Alphanumeric'],
        ['GORR', '1', '1', 'Alphanumeric'],
        ['HAUTR', '3', '1', 'Alphanumeric'],
        ['HROR', '3', '1', 'Alphanumeric'],
        ['LOAR', '9', '1', 'Alphanumeric'],
        ['LSOAR', '9', '1', 'Alphanumeric'],
        ['MARSTAT', '1', '1', 'Numeric'],
        ['NAMEMAID', '40', '1', 'Alphanumeric'],
        ['NHSNO', '15', '5', 'Alphanumeric'],
        ['NHSNORSS', '15', '1', 'Alphanumeric'],
        ['OCCDT', '75', '1', 'Alphanumeric'],
        ['OCCFFT', '75', '4', 'Alphanumeric'],
        ['OCCTYPE', '1', '1', 'Alphanumeric'],
        ['PCDR', '8', '1', 'Alphanumeric'],
        ['POBT', '100', '1', 'Alphanumeric'],
        ['SEX', '1', '1', 'Numeric'],
        ['SNAMD', '50', '1', 'Alphanumeric'],
        ['WARDR', '6', '1', 'Alphanumeric'],
        ['AGECS', '3', '1', 'Numeric'],
        ['EMPRSSDM', '1', '1', 'Alphanumeric'],
        ['EMPRSSHF', '1', '1', 'Alphanumeric'],
        ['EMPSECDM', '1', '1', 'Alphanumeric'],
        ['EMPSECHF', '1', '1', 'Alphanumeric'],
        ['EMPSTDM', '1', '1', 'Alphanumeric'],
        ['EMPSTHF', '1', '1', 'Alphanumeric'],
        ['INDDMT', '20', '1', 'Alphanumeric'],
        ['INDHFT', '20', '1', 'Alphanumeric'],
        ['NAMEHF', '100', '1', 'Alphanumeric'],
        ['NAMEM', '20', '1', 'Alphanumeric'],
        ['OCC90DM', '3', '1', 'Alphanumeric'],
        ['OCC90HF', '3', '1', 'Alphanumeric'],
        ['OCCHFT', '75', '1', 'Alphanumeric'],
        ['OCCMT', '75', '1', 'Alphanumeric'],
        ['RETINDM', '1', '1', 'Numeric'],
        ['RETINDHF', '1', '1', 'Numeric'],
        ['SCLASDM', '1', '1', 'Alphanumeric'],
        ['SCLASHF', '1', '1', 'Alphanumeric'],
        ['SEC90DM', '2', '1', 'Alphanumeric'],
        ['SEC90HF', '2', '1', 'Alphanumeric'],
        ['SECCATDM', '2', '1', 'Alphanumeric'],
        ['SECCATHF', '2', '1', 'Alphanumeric'],
        ['SECCLRDM', '2', '1', 'Alphanumeric'],
        ['SECCLRHF', '2', '1', 'Alphanumeric'],
        ['SOC2KDM', '4', '1', 'Alphanumeric'],
        ['SOC2KHF', '4', '1', 'Alphanumeric'],
        ['SOC90DM', '3', '1', 'Alphanumeric'],
        ['SOC90HF', '3', '1', 'Alphanumeric'],
        ['CERTTYPE', '2', '1', 'Numeric'],
        ['CORAREAT', '100', '1', 'Alphanumeric'],
        ['CORCERTT', '75', '1', 'Alphanumeric'],
        ['DOINQT', '50', '1', 'Alphanumeric'],
        ['DOR', '8', '1', 'Alphanumeric'],
        ['INQCERT', '1', '1', 'Numeric'],
        ['POSTMORT', '2', '1', 'Numeric'],
        ['CERTIFER', '50', '1', 'Alphanumeric'],
        ['NAMEC', '50', '1', 'Alphanumeric'],
        ['NAMECON', '30', '1', 'Alphanumeric'],
        ['CODFFT_1 to CODFFT_65', '75', '65', 'Alphanumeric'],
        ['CCG9POD', '9', '1', 'Alphanumeric'],
        ['CCG9R', '9', '1', 'Alphanumeric'],
        ['GOR9R', '9', '1', 'Alphanumeric'],
        ['WARD9R', '9', '1', 'Alphanumeric']
      ].freeze

      # Extracted from columns H-K of
      # "doc/spec/MBIS2016 Common Dataset for Births description of variables v6.0.xlsx"
      # passed through: $ sed -e "s/\t/', '/g" -e "s/^/        ['/" -e "s/$/'],/"
      BIRTH_SPEC_FIELDS = [
        ['Field Label', 'Length', 'Occurrences', 'Data Type'],
        ['MBISM204ID', '15', '1', 'Alphanumeric'],
        ['LEDRID', '13', '1', 'Numeric'],
        ['BIRTHWGT', '4', '1', 'Numeric'],
        ['CCGPOB', '3', '1', 'Alphanumeric'],
        ['CESTRSS', '5', '1', 'Alphanumeric'],
        ['CTYPOB', '2', '1', 'Alphanumeric'],
        ['DOBF', '10', '1', 'Alphanumeric'],
        ['DOR', '8', '1', 'Alphanumeric'],
        ['ESTTYPEB', '2', '1', 'Alphanumeric'],
        ['HAUTPOB', '3', '1', 'Alphanumeric'],
        ['HROPOB', '3', '1', 'Alphanumeric'],
        ['LOARPOB', '9', '1', 'Alphanumeric'],
        ['LSOARPOB', '9', '1', 'Alphanumeric'],
        ['MULTBTH', '1', '1', 'Numeric'],
        ['MULTTYPE', '2', '1', 'Numeric'],
        ['NHSIND', '1', '1', 'Numeric'],
        ['PCDPOB', '8', '1', 'Alphanumeric'],
        ['POBT', '100', '1', 'Alphanumeric'],
        ['SBIND', '1', '1', 'Numeric'],
        ['DOB', '8', '1', 'Alphanumeric'],
        ['FNAMCH1', '20', '1', 'Alphanumeric'],
        ['FNAMCH2', '20', '1', 'Alphanumeric'],
        ['FNAMCH3', '20', '1', 'Alphanumeric'],
        ['FNAMCHX', '75', '2  1', 'Alphanumeric'],
        ['GESTATN', '2', '1', 'Numeric'],
        ['ICDPV_1 to ICDPV_20', '5', '20', 'Alphanumeric'],
        ['ICDPVF_1 to ICDPVF_20', '5', '20', 'Alphanumeric'],
        ['NHSNO', '15', '1', 'Alphanumeric'],
        ['SEX', '1', '1', 'Numeric'],
        ['SNAMCH', '50', '1', 'Alphanumeric'],
        ['COD10R_1 to COD10R_20', '2', '20', 'Alphanumeric'],
        ['CODFFT', '75', '5', 'Alphanumeric'],
        ['DEATHLAB', '1', '1', 'Alphanumeric'],
        ['WIGWO10', '1', '1', 'Numeric'],
        ['ADDRMT', '200', '1', 'Alphanumeric'],
        ['AGEBF', '4', '1', 'Alphanumeric'],
        ['AGEBM', '4', '1', 'Alphanumeric'],
        ['AGEMF', '4', '1', 'Alphanumeric'],
        ['AGEMM', '4', '1', 'Alphanumeric'],
        ['BTHIMAR', '2', '1', 'Alphanumeric'],
        ['CCGRM', '3', '1', 'Alphanumeric'],
        ['CTRYPOBF', '4', '1', 'Alphanumeric'],
        ['CTRYPOBM', '4', '1', 'Alphanumeric'],
        ['CTYDRM', '2', '1', 'Alphanumeric'],
        ['CTYRM', '2', '1', 'Alphanumeric'],
        ['DOBM', '10', '1', 'Alphanumeric'],
        ['DURMAR', '4', '1', 'Numeric'],
        ['EMPSECF', '2', '1', 'Alphanumeric'],
        ['EMPSECM', '2', '1', 'Alphanumeric'],
        ['EMPSTF', '2', '1', 'Alphanumeric'],
        ['EMPSTM', '2', '1', 'Alphanumeric'],
        ['FNAMF', '20', '3  1', 'Alphanumeric'],
        ['FNAMFX', '75', '2  1', 'Alphanumeric'],
        ['FNAMM', '20', '3  1 ', 'Alphanumeric'],
        ['FNAMMX', '75', '2  1', 'Alphanumeric'],
        ['GORRM', '1', '1', 'Alphanumeric'],
        ['HAUTRM', '3', '1', 'Alphanumeric'],
        ['HRORM', '3', '1', 'Alphanumeric'],
        ['LOARM', '9', '1', 'Alphanumeric'],
        ['LSOARM', '9', '1', 'Alphanumeric'],
        ['NAMEMAID', '40', '1', 'Alphanumeric'],
        ['PCDRM', '8', '1', 'Alphanumeric'],
        ['SECCATF', '2', '1', 'Alphanumeric'],
        ['SECCATM', '2', '1', 'Alphanumeric'],
        ['SNAMF', '50', '1', 'Alphanumeric'],
        ['SNAMM', '50', '1', 'Alphanumeric'],
        ['SNAMMCF', '40', '1', 'Alphanumeric'],
        ['SOC2KF', '4', '1', 'Alphanumeric'],
        ['SOC2KM', '4', '1', 'Alphanumeric'],
        ['SOC90F', '3', '1', 'Alphanumeric'],
        ['SOC90M', '3', '1', 'Alphanumeric'],
        ['STREGRM', '1', '1', 'Alphanumeric'],
        ['WARDRM', '6', '1', 'Alphanumeric'],
        ['CCG9POB', '9', '1', 'Alphanumeric'],
        ['CCG9RM', '9', '1', 'Alphanumeric'],
        ['GOR9RM', '9', '1', 'Alphanumeric'],
        ['WARD9M', '9', '1', 'Alphanumeric']
      ] + [
        ['MATTAB', '1', '1', 'Numeric'] # Not in spec file
      ]
      # rubocop:enable Style/WordArray

      included do
        # Returns the data schema
        # rubocop:disable Layout/LineLength
        # This can be emitted to a CSV file by running:
        # $ E_TYPE=PSDEATH DEST=death_file_format.csv rails runner -e production "recs = Export::DelimitedFile.new(nil, ENV['E_TYPE'], nil).data_schema; CSV.open(ENV['DEST'], 'w', headers: recs.first.keys, write_headers: true) { |csv| recs.each { |rec| csv << rec } }"
        # $ E_TYPE=PSBIRTH DEST=birth_file_format.csv rails runner -e production "recs = Export::DelimitedFile.new(nil, ENV['E_TYPE'], nil).data_schema; CSV.open(ENV['DEST'], 'w', headers: recs.first.keys, write_headers: true) { |csv| recs.each { |rec| csv << rec } }"
        # rubocop:enable Layout/LineLength
        def data_schema
          # batch = EBatch.new(e_type: @e_type)
          # demographic_fields = Import::DelimitedFile.new(nil, batch).send(:demographic_fields)
          db_columns = (@e_type == 'PSDEATH' ? Pseudo::DeathData : Pseudo::BirthData).columns_hash
          recs = @col_fields.zip(header_rows.first).collect(&:flatten)
          recs = recs.select { |_col, _field, header| header } # Only select ones with a header
          recs.collect do |_col, field, header|
            # demog = demographic_fields.include?(field)
            type = db_columns[field]&.type
            _spec_label, spec_length, _spec_occurences, spec_type = (spec_column(header) ||
                                                                     spec_column(field.upcase))
            # Some columns have had their types changed in migrations
            # egrep -hi '^ *change.*(birth|death)' db/migrate/*rb|grep -v bigint| \
            #   sed -e 's/^ */      # /'|sort -u
            # Treat identifiable columns that were never in database columns as strings
            # because some of these changed under LEDR, or had leading zeros
            if (type == :string && spec_type == 'Numeric') ||
               (type.nil? && spec_type == 'Numeric')
              spec_type = 'Alphanumeric'
            end

            {
              column_name: header,
              length: spec_length,
              type: spec_type
            }
          end
        end

        def spec_column(field)
          spec_columns = (@e_type == 'PSDEATH' ? DEATH_SPEC_FIELDS : BIRTH_SPEC_FIELDS)
          spec_columns.find do |label, _length, occurences, _spec_type|
            if field && (label =~ / to | - / || occurences.to_i > 1)
              field1 = field.sub(/_[0-9]+$/, '_1').sub(/_?([0-9])[a-e]/i, '_1')
              label1 = label.split.first.sub(/(_[0-9]+)?$/, '_1')
              label1 == field1
            else
              label == field
            end
          end
        end
      end
    end
  end
end
