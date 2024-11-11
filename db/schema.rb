# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[6.1].define(version: 2018_12_21_110625) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "birth_data", primary_key: "birth_dataid", force: :cascade do |t|
    t.bigint "ppatient_id"
    t.string "birthwgt"
    t.string "caind"
    t.string "ccgpob"
    t.string "cestrss"
    t.string "ctypob"
    t.string "dobf"
    t.string "dor"
    t.string "esttypeb"
    t.string "hautpob"
    t.string "hropob"
    t.string "loarpob"
    t.string "lsoarpob"
    t.integer "multbth"
    t.string "multtype"
    t.integer "nhsind"
    t.string "cod10r_1"
    t.string "cod10r_2"
    t.string "cod10r_3"
    t.string "cod10r_4"
    t.string "cod10r_5"
    t.string "cod10r_6"
    t.string "cod10r_7"
    t.string "cod10r_8"
    t.string "cod10r_9"
    t.string "cod10r_10"
    t.string "cod10r_11"
    t.string "cod10r_12"
    t.string "cod10r_13"
    t.string "cod10r_14"
    t.string "cod10r_15"
    t.string "cod10r_16"
    t.string "cod10r_17"
    t.string "cod10r_18"
    t.string "cod10r_19"
    t.string "cod10r_20"
    t.integer "wigwo10"
    t.string "agebf"
    t.string "agebm"
    t.string "agemf"
    t.string "agemm"
    t.string "bthimar"
    t.string "ccgrm"
    t.string "ctrypobf"
    t.string "ctrypobm"
    t.string "ctydrm"
    t.string "ctyrm"
    t.string "durmar"
    t.string "empsecf"
    t.string "empsecm"
    t.string "empstf"
    t.string "empstm"
    t.string "gorrm"
    t.string "hautrm"
    t.string "hrorm"
    t.string "loarm"
    t.string "lsoarm"
    t.string "seccatf"
    t.string "seccatm"
    t.string "soc2kf"
    t.string "soc2km"
    t.string "soc90f"
    t.string "soc90m"
    t.string "stregrm"
    t.string "wardrm"
    t.string "ccg9pob"
    t.string "ccg9rm"
    t.string "gor9rm"
    t.string "ward9m"
    t.integer "mattab"
    t.index ["ppatient_id"], name: "index_birth_data_on_ppatient_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.integer "dataset_version_id"
    t.integer "sort"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "choice_types", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "classifications", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "data_dictionary_elements", force: :cascade do |t|
    t.string "name"
    t.string "group"
    t.string "status"
    t.string "format_length"
    t.string "national_codes"
    t.string "link"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "data_item_groups", force: :cascade do |t|
    t.bigint "data_item_id"
    t.bigint "group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["data_item_id"], name: "index_data_item_groups_on_data_item_id"
    t.index ["group_id"], name: "index_data_item_groups_on_group_id"
  end

  create_table "data_items", force: :cascade do |t|
    t.string "name"
    t.string "identifier"
    t.string "annotation"
    t.string "description"
    t.integer "min_occurs"
    t.integer "max_occurs"
    t.boolean "common"
    t.integer "entity_id"
    t.integer "xml_type_id"
    t.integer "data_dictionary_element_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "data_source_item_categories", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "data_source_items", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "governance"
    t.integer "data_source_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "data_source_item_category_id"
    t.integer "occurrences"
    t.string "category"
    t.index ["name", "data_source_id"], name: "index_data_source_items_on_name_and_data_source_id", unique: true
  end

  create_table "data_sources", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "terms"
    t.index ["name"], name: "index_data_sources_on_name", unique: true
  end

  create_table "dataset_versions", force: :cascade do |t|
    t.integer "dataset_id"
    t.string "semver_version"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "datasets", force: :cascade do |t|
    t.string "name"
    t.string "full_name"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "death_data", primary_key: "death_dataid", force: :cascade do |t|
    t.bigint "ppatient_id"
    t.string "cestrssr"
    t.string "ceststay"
    t.string "ccgpod"
    t.string "cestrss"
    t.string "cod10r_1"
    t.string "cod10r_2"
    t.string "cod10r_3"
    t.string "cod10r_4"
    t.string "cod10r_5"
    t.string "cod10r_6"
    t.string "cod10r_7"
    t.string "cod10r_8"
    t.string "cod10r_9"
    t.string "cod10r_10"
    t.string "cod10r_11"
    t.string "cod10r_12"
    t.string "cod10r_13"
    t.string "cod10r_14"
    t.string "cod10r_15"
    t.string "cod10r_16"
    t.string "cod10r_17"
    t.string "cod10r_18"
    t.string "cod10r_19"
    t.string "cod10r_20"
    t.string "cod10rf_1"
    t.string "cod10rf_2"
    t.string "cod10rf_3"
    t.string "cod10rf_4"
    t.string "cod10rf_5"
    t.string "cod10rf_6"
    t.string "cod10rf_7"
    t.string "cod10rf_8"
    t.string "cod10rf_9"
    t.string "cod10rf_10"
    t.string "cod10rf_11"
    t.string "cod10rf_12"
    t.string "cod10rf_13"
    t.string "cod10rf_14"
    t.string "cod10rf_15"
    t.string "cod10rf_16"
    t.string "cod10rf_17"
    t.string "cod10rf_18"
    t.string "cod10rf_19"
    t.string "cod10rf_20"
    t.string "codt_1"
    t.string "codt_2"
    t.string "codt_3"
    t.string "codt_4"
    t.string "codt_5"
    t.string "codt_6"
    t.string "ctydpod"
    t.string "ctypod"
    t.string "dester"
    t.string "doddy"
    t.string "dodmt"
    t.integer "dodyr"
    t.string "esttyped"
    t.string "hautpod"
    t.string "hropod"
    t.string "icd_1"
    t.string "icd_2"
    t.string "icd_3"
    t.string "icd_4"
    t.string "icd_5"
    t.string "icd_6"
    t.string "icd_7"
    t.string "icd_8"
    t.string "icd_9"
    t.string "icd_10"
    t.string "icd_11"
    t.string "icd_12"
    t.string "icd_13"
    t.string "icd_14"
    t.string "icd_15"
    t.string "icd_16"
    t.string "icd_17"
    t.string "icd_18"
    t.string "icd_19"
    t.string "icd_20"
    t.string "icdf_1"
    t.string "icdf_2"
    t.string "icdf_3"
    t.string "icdf_4"
    t.string "icdf_5"
    t.string "icdf_6"
    t.string "icdf_7"
    t.string "icdf_8"
    t.string "icdf_9"
    t.string "icdf_10"
    t.string "icdf_11"
    t.string "icdf_12"
    t.string "icdf_13"
    t.string "icdf_14"
    t.string "icdf_15"
    t.string "icdf_16"
    t.string "icdf_17"
    t.string "icdf_18"
    t.string "icdf_19"
    t.string "icdf_20"
    t.string "icdpv_1"
    t.string "icdpv_2"
    t.string "icdpv_3"
    t.string "icdpv_4"
    t.string "icdpv_5"
    t.string "icdpv_6"
    t.string "icdpv_7"
    t.string "icdpv_8"
    t.string "icdpv_9"
    t.string "icdpv_10"
    t.string "icdpv_11"
    t.string "icdpv_12"
    t.string "icdpv_13"
    t.string "icdpv_14"
    t.string "icdpv_15"
    t.string "icdpv_16"
    t.string "icdpv_17"
    t.string "icdpv_18"
    t.string "icdpv_19"
    t.string "icdpv_20"
    t.string "icdpvf_1"
    t.string "icdpvf_2"
    t.string "icdpvf_3"
    t.string "icdpvf_4"
    t.string "icdpvf_5"
    t.string "icdpvf_6"
    t.string "icdpvf_7"
    t.string "icdpvf_8"
    t.string "icdpvf_9"
    t.string "icdpvf_10"
    t.string "icdpvf_11"
    t.string "icdpvf_12"
    t.string "icdpvf_13"
    t.string "icdpvf_14"
    t.string "icdpvf_15"
    t.string "icdpvf_16"
    t.string "icdpvf_17"
    t.string "icdpvf_18"
    t.string "icdpvf_19"
    t.string "icdpvf_20"
    t.string "icdsc"
    t.string "icdscf"
    t.string "icdu"
    t.string "icduf"
    t.string "icdfuture1"
    t.string "icdfuture2"
    t.integer "lineno9_1"
    t.integer "lineno9_2"
    t.integer "lineno9_3"
    t.integer "lineno9_4"
    t.integer "lineno9_5"
    t.integer "lineno9_6"
    t.integer "lineno9_7"
    t.integer "lineno9_8"
    t.integer "lineno9_9"
    t.integer "lineno9_10"
    t.integer "lineno9_11"
    t.integer "lineno9_12"
    t.integer "lineno9_13"
    t.integer "lineno9_14"
    t.integer "lineno9_15"
    t.integer "lineno9_16"
    t.integer "lineno9_17"
    t.integer "lineno9_18"
    t.integer "lineno9_19"
    t.integer "lineno9_20"
    t.integer "lineno9f_1"
    t.integer "lineno9f_2"
    t.integer "lineno9f_3"
    t.integer "lineno9f_4"
    t.integer "lineno9f_5"
    t.integer "lineno9f_6"
    t.integer "lineno9f_7"
    t.integer "lineno9f_8"
    t.integer "lineno9f_9"
    t.integer "lineno9f_10"
    t.integer "lineno9f_11"
    t.integer "lineno9f_12"
    t.integer "lineno9f_13"
    t.integer "lineno9f_14"
    t.integer "lineno9f_15"
    t.integer "lineno9f_16"
    t.integer "lineno9f_17"
    t.integer "lineno9f_18"
    t.integer "lineno9f_19"
    t.integer "lineno9f_20"
    t.string "loapod"
    t.string "lsoapod"
    t.string "nhsind"
    t.integer "ploacc10"
    t.string "podqual"
    t.string "podt"
    t.string "wigwo10"
    t.string "wigwo10f"
    t.integer "agecunit"
    t.string "ccgr"
    t.string "ctrypob"
    t.string "ctryr"
    t.string "ctydr"
    t.string "ctyr"
    t.string "gorr"
    t.string "hautr"
    t.string "hror"
    t.string "loar"
    t.string "lsoar"
    t.string "marstat"
    t.string "occdt"
    t.string "occfft_1"
    t.string "occfft_2"
    t.string "occfft_3"
    t.string "occfft_4"
    t.string "occtype"
    t.string "wardr"
    t.string "emprssdm"
    t.string "emprsshf"
    t.string "empsecdm"
    t.string "empsechf"
    t.string "empstdm"
    t.string "empsthf"
    t.string "inddmt"
    t.string "indhft"
    t.string "occ90dm"
    t.string "occ90hf"
    t.string "occhft"
    t.string "occmt"
    t.string "retindm"
    t.string "retindhf"
    t.string "sclasdm"
    t.string "sclashf"
    t.string "sec90dm"
    t.string "sec90hf"
    t.string "seccatdm"
    t.string "seccathf"
    t.string "secclrdm"
    t.string "secclrhf"
    t.string "soc2kdm"
    t.string "soc2khf"
    t.string "soc90dm"
    t.string "soc90hf"
    t.integer "certtype"
    t.string "corareat"
    t.string "corcertt"
    t.string "doinqt"
    t.string "dor"
    t.integer "inqcert"
    t.integer "postmort"
    t.string "codfft_1"
    t.string "codfft_2"
    t.string "codfft_3"
    t.string "codfft_4"
    t.string "codfft_5"
    t.string "codfft_6"
    t.string "codfft_7"
    t.string "codfft_8"
    t.string "codfft_9"
    t.string "codfft_10"
    t.string "codfft_11"
    t.string "codfft_12"
    t.string "codfft_13"
    t.string "codfft_14"
    t.string "codfft_15"
    t.string "codfft_16"
    t.string "codfft_17"
    t.string "codfft_18"
    t.string "codfft_19"
    t.string "codfft_20"
    t.string "codfft_21"
    t.string "codfft_22"
    t.string "codfft_23"
    t.string "codfft_24"
    t.string "codfft_25"
    t.string "codfft_26"
    t.string "codfft_27"
    t.string "codfft_28"
    t.string "codfft_29"
    t.string "codfft_30"
    t.string "codfft_31"
    t.string "codfft_32"
    t.string "codfft_33"
    t.string "codfft_34"
    t.string "codfft_35"
    t.string "codfft_36"
    t.string "codfft_37"
    t.string "codfft_38"
    t.string "codfft_39"
    t.string "codfft_40"
    t.string "codfft_41"
    t.string "codfft_42"
    t.string "codfft_43"
    t.string "codfft_44"
    t.string "codfft_45"
    t.string "codfft_46"
    t.string "codfft_47"
    t.string "codfft_48"
    t.string "codfft_49"
    t.string "codfft_50"
    t.string "codfft_51"
    t.string "codfft_52"
    t.string "codfft_53"
    t.string "codfft_54"
    t.string "codfft_55"
    t.string "codfft_56"
    t.string "codfft_57"
    t.string "codfft_58"
    t.string "codfft_59"
    t.string "codfft_60"
    t.string "codfft_61"
    t.string "codfft_62"
    t.string "codfft_63"
    t.string "codfft_64"
    t.string "codfft_65"
    t.string "ccg9pod"
    t.string "ccg9r"
    t.string "gor9r"
    t.string "ward9r"
    t.index ["ppatient_id"], name: "index_death_data_on_ppatient_id"
  end

  create_table "directorates", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: true
  end

  create_table "divisions", id: :serial, force: :cascade do |t|
    t.integer "directorate_id"
    t.string "name"
    t.string "head_of_profession"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: true
  end

  create_table "e_action", primary_key: "e_actionid", id: :serial, force: :cascade do |t|
    t.bigint "e_batchid"
    t.string "e_actiontype", limit: 255
    t.datetime "started"
    t.string "startedby", limit: 255
    t.datetime "finished"
    t.string "comments", limit: 4000
    t.string "status", limit: 255
    t.bigint "lock_version", default: 0, null: false
    t.index ["e_batchid"], name: "index_e_action_on_e_batchid"
    t.index ["status"], name: "index_e_action_on_status"
  end

  create_table "e_batch", primary_key: "e_batchid", id: :serial, force: :cascade do |t|
    t.string "e_type", limit: 255
    t.string "provider", limit: 255
    t.string "media", limit: 255
    t.string "original_filename", limit: 255
    t.string "cleaned_filename", limit: 255
    t.bigint "numberofrecords"
    t.datetime "date_reference1"
    t.datetime "date_reference2"
    t.bigint "e_batchid_traced"
    t.string "comments", limit: 255
    t.string "digest", limit: 40
    t.bigint "lock_version", default: 0, null: false
    t.string "inprogress", limit: 50
    t.string "registryid", limit: 255
    t.integer "on_hold", limit: 2
    t.index ["registryid", "e_type", "provider"], name: "index_e_batch_on_registryid_and_e_type_and_provider"
  end

  create_table "e_workflow", primary_key: "e_workflowid", id: :serial, force: :cascade do |t|
    t.string "e_type", limit: 255
    t.string "provider", limit: 255
    t.string "last_e_actiontype", limit: 255
    t.string "next_e_actiontype", limit: 255
    t.string "comments", limit: 255
    t.integer "sort", limit: 2
    t.index ["e_type", "last_e_actiontype", "next_e_actiontype"], name: "e_workflow_etype_leat_neat_ix"
  end

  create_table "end_uses", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "entities", force: :cascade do |t|
    t.string "name"
    t.string "title"
    t.string "description"
    t.integer "parent_id"
    t.integer "dataset_version_id"
    t.integer "min_occurs"
    t.integer "max_occurs"
    t.integer "sort"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "enumeration_values", force: :cascade do |t|
    t.string "enumeration_value"
    t.string "annotation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "error_fingerprints", primary_key: "error_fingerprintid", id: :string, force: :cascade do |t|
    t.string "ticket_url"
    t.string "status"
    t.integer "count"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "causal_error_fingerprintid"
    t.index ["causal_error_fingerprintid"], name: "index_error_fingerprints_on_causal_error_fingerprintid"
  end

  create_table "error_logs", primary_key: "error_logid", id: :string, force: :cascade do |t|
    t.string "error_fingerprintid"
    t.string "error_class"
    t.text "description"
    t.string "user_roles"
    t.text "lines"
    t.text "parameters_yml"
    t.string "url"
    t.string "user_agent"
    t.string "ip"
    t.string "hostname"
    t.string "database"
    t.float "clock_drift"
    t.string "svn_revision"
    t.integer "port"
    t.integer "process_id"
    t.string "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "user_id"
    t.index ["error_fingerprintid"], name: "index_error_logs_on_error_fingerprintid"
  end

  create_table "genetic_sequence_variants", primary_key: "geneticsequencevariantid", id: :serial, force: :cascade do |t|
    t.integer "genetic_test_result_id"
    t.decimal "humangenomebuild", precision: 19
    t.text "referencetranscriptid"
    t.text "genomicchange"
    t.text "codingdnasequencechange"
    t.text "proteinimpact"
    t.text "clinvarid"
    t.text "cosmicid"
    t.decimal "variantpathclass", precision: 19
    t.decimal "variantlocation", precision: 19
    t.text "exonintroncodonnumber"
    t.decimal "sequencevarianttype", precision: 19
    t.decimal "variantimpact", precision: 19
    t.decimal "variantgenotype", precision: 19
    t.float "variantallelefrequency"
    t.text "variantreport"
    t.text "raw_record"
    t.integer "age"
    t.index ["genetic_test_result_id"], name: "index_genetic_sequence_variants_on_genetic_test_result_id"
  end

  create_table "genetic_test_results", primary_key: "genetictestresultid", id: :serial, force: :cascade do |t|
    t.integer "molecular_data_id"
    t.decimal "teststatus", precision: 19
    t.decimal "geneticaberrationtype", precision: 19
    t.text "karyotypearrayresult"
    t.decimal "rapidniptresult", precision: 19
    t.text "gene"
    t.text "genotype"
    t.decimal "zygosity", precision: 19
    t.decimal "chromosomenumber", precision: 19
    t.decimal "chromosomearm", precision: 19
    t.text "cytogeneticband"
    t.text "fusionpartnergene"
    t.decimal "fusionpartnerchromosomenumber", precision: 19
    t.decimal "fusionpartnerchromosomearm", precision: 19
    t.text "fusionpartnercytogeneticband"
    t.decimal "msistatus", precision: 19
    t.text "report"
    t.decimal "geneticinheritance", precision: 19
    t.text "percentmutantalabkaryotype"
    t.decimal "oncotypedxbreastrecurscore", precision: 19
    t.text "raw_record"
    t.integer "age"
    t.index ["molecular_data_id"], name: "index_genetic_test_results_on_molecular_data_id"
  end

  create_table "groups", force: :cascade do |t|
    t.string "name"
    t.string "shortdesc"
    t.string "description"
    t.integer "dataset_version_id"
    t.integer "sort"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "memberships", id: :serial, force: :cascade do |t|
    t.integer "team_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "senior"
    t.index ["team_id"], name: "index_memberships_on_team_id"
    t.index ["user_id", "team_id"], name: "index_memberships_on_user_id_and_team_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "molecular_data", primary_key: "molecular_dataid", force: :cascade do |t|
    t.bigint "ppatient_id"
    t.text "providercode"
    t.text "practitionercode"
    t.text "patienttype"
    t.integer "moleculartestingtype"
    t.date "requesteddate"
    t.date "collecteddate"
    t.date "receiveddate"
    t.date "authoriseddate"
    t.integer "indicationcategory"
    t.text "clinicalindication"
    t.text "organisationcode_testresult"
    t.text "servicereportidentifier"
    t.integer "specimentype"
    t.text "otherspecimentype"
    t.text "tumourpercentage"
    t.integer "specimenprep"
    t.integer "karyotypingmethod"
    t.text "genetictestscope"
    t.text "isresearchtest"
    t.jsonb "genetictestresults"
    t.text "sourcetype"
    t.text "comments"
    t.date "datefirstnotified"
    t.text "raw_record"
    t.integer "age"
    t.index ["ppatient_id"], name: "index_molecular_data_on_ppatient_id"
  end

  create_table "namespaces", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "node_categories", force: :cascade do |t|
    t.bigint "node_id"
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_node_categories_on_category_id"
    t.index ["node_id"], name: "index_node_categories_on_node_id"
  end

  create_table "nodes", force: :cascade do |t|
    t.integer "dataset_version_id"
    t.string "type"
    t.integer "parent_id"
    t.string "name"
    t.string "reference"
    t.string "annotation"
    t.string "description"
    t.integer "xml_type_id"
    t.integer "data_dictionary_element_id"
    t.integer "choice_type_id"
    t.integer "sort"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "category_id"
    t.integer "min_occurs"
    t.integer "max_occurs"
  end

  create_table "notifications", id: :serial, force: :cascade do |t|
    t.string "title"
    t.string "body"
    t.string "created_by"
    t.integer "notification_template_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin_users"
    t.boolean "odr_users"
    t.boolean "senior_users"
    t.integer "user_id"
    t.integer "project_id"
    t.integer "team_id"
    t.boolean "all_users"
    t.index ["notification_template_id"], name: "index_notifications_on_notification_template_id"
    t.index ["project_id"], name: "index_notifications_on_project_id"
    t.index ["team_id"], name: "index_notifications_on_team_id"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "outputs", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ppatient_rawdata", primary_key: "ppatient_rawdataid", force: :cascade do |t|
    t.binary "rawdata"
    t.binary "decrypt_key"
  end

  create_table "ppatients", force: :cascade do |t|
    t.integer "e_batch_id"
    t.bigint "ppatient_rawdata_id"
    t.string "type"
    t.text "pseudo_id1"
    t.text "pseudo_id2"
    t.integer "pseudonymisation_keyid"
    t.index ["e_batch_id"], name: "index_ppatients_on_e_batch_id"
    t.index ["ppatient_rawdata_id"], name: "index_ppatients_on_ppatient_rawdata_id"
    t.index ["pseudo_id1"], name: "index_ppatients_on_pseudo_id1"
    t.index ["pseudo_id2"], name: "index_ppatients_on_pseudo_id2"
  end

  create_table "prescription_data", primary_key: "prescription_dataid", force: :cascade do |t|
    t.bigint "ppatient_id"
    t.text "part_month"
    t.date "presc_date"
    t.text "presc_postcode"
    t.text "pco_code"
    t.text "pco_name"
    t.text "practice_code"
    t.text "practice_name"
    t.text "nic"
    t.text "presc_quantity"
    t.integer "item_number"
    t.text "unit_of_measure"
    t.integer "pay_quantity"
    t.text "drug_paid"
    t.text "bnf_code"
    t.integer "pat_age"
    t.text "pf_exempt_cat"
    t.text "etp_exempt_cat"
    t.text "etp_indicator"
    t.bigint "pf_id"
    t.bigint "ampp_id"
    t.bigint "vmpp_id"
    t.text "sex"
    t.text "form_type"
    t.text "chemical_substance_bnf"
    t.text "chemical_substance_bnf_descr"
    t.bigint "vmp_id"
    t.text "vmp_name"
    t.text "vtm_name"
    t.index ["bnf_code"], name: "index_prescription_data_on_bnf_code"
    t.index ["ppatient_id"], name: "index_prescription_data_on_ppatient_id"
  end

  create_table "project_attachments", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.string "name"
    t.string "comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "attachment_file_name"
    t.string "attachment_content_type"
    t.integer "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.binary "attachment_contents"
    t.string "digest"
    t.index ["project_id"], name: "index_project_attachments_on_project_id"
  end

  create_table "project_classifications", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.integer "classification_id"
    t.index ["classification_id"], name: "index_project_classifications_on_classification_id"
    t.index ["project_id"], name: "index_project_classifications_on_project_id"
  end

  create_table "project_comments", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.integer "user_id"
    t.string "user_role"
    t.string "comment_type"
    t.text "comment"
    t.integer "project_data_source_item_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_data_source_item_id"], name: "index_project_comments_on_project_data_source_item_id"
    t.index ["project_id"], name: "index_project_comments_on_project_id"
    t.index ["user_id"], name: "index_project_comments_on_user_id"
  end

  create_table "project_data_end_users", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "ts_cs_accepted"
  end

  create_table "project_data_passwords", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.binary "rawdata"
    t.datetime "expired"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_project_data_passwords_on_project_id"
  end

  create_table "project_data_source_items", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.integer "data_source_item_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "approved"
    t.index ["data_source_item_id"], name: "index_project_data_source_items_on_data_source_item_id"
    t.index ["project_id"], name: "index_project_data_source_items_on_project_id"
  end

  create_table "project_end_uses", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.integer "end_use_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["end_use_id"], name: "index_project_end_uses_on_end_use_id"
    t.index ["project_id"], name: "index_project_end_uses_on_project_id"
  end

  create_table "project_memberships", id: :serial, force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "membership_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "senior"
    t.index ["membership_id"], name: "index_project_memberships_on_membership_id"
    t.index ["project_id", "membership_id"], name: "index_project_memberships_on_project_id_and_membership_id", unique: true
    t.index ["project_id"], name: "index_project_memberships_on_project_id"
  end

  create_table "project_outputs", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.integer "output_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["output_id"], name: "index_project_outputs_on_output_id"
    t.index ["project_id"], name: "index_project_outputs_on_project_id"
  end

  create_table "projects", id: :serial, force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "z_project_status_id"
    t.date "start_data_date"
    t.date "end_data_date"
    t.integer "team_id"
    t.text "how_data_will_be_used"
    t.string "head_of_profession"
    t.integer "senior_user_id"
    t.string "data_access_address"
    t.string "data_access_postcode"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "team_data_source_id"
    t.boolean "details_approved"
    t.boolean "members_approved"
    t.string "end_use_other"
    t.boolean "data_to_contact_others"
    t.text "data_to_contact_others_desc"
    t.boolean "data_already_held_for_project"
    t.text "data_linkage"
    t.string "frequency"
    t.string "frequency_other"
    t.boolean "acg_support"
    t.string "acg_who"
    t.date "acg_date"
    t.string "outputs_other"
    t.text "cohort_inclusion_exclusion_criteria"
    t.boolean "informed_patient_consent"
    t.boolean "ethics_approval_obtained"
    t.string "ethics_approval_nrec_name"
    t.string "ethics_approval_nrec_ref"
    t.boolean "legal_ethical_approved"
    t.text "legal_ethical_approval_comments"
    t.boolean "delegate_approved"
    t.boolean "direct_care"
    t.boolean "section_251_exempt"
    t.string "cag_ref"
    t.date "date_of_approval"
    t.date "date_of_renewal"
    t.boolean "regulation_health_services"
    t.string "caldicott_email"
    t.boolean "informed_patient_consent_mortality"
    t.boolean "s42_of_srsa"
    t.boolean "approved_research_accreditation"
    t.string "trackwise_id"
    t.integer "clone_of"
    t.index ["team_id"], name: "index_projects_on_team_id"
    t.index ["z_project_status_id"], name: "index_projects_on_z_project_status_id"
  end

  create_table "pseudonymisation_keys", primary_key: "pseudonymisation_keyid", id: :serial, force: :cascade do |t|
    t.text "key_name"
    t.date "startdate"
    t.date "enddate"
    t.text "comments"
    t.string "e_type", limit: 255
    t.string "provider", limit: 255
  end

  create_table "team_data_sources", id: :serial, force: :cascade do |t|
    t.integer "team_id"
    t.integer "data_source_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["data_source_id", "team_id"], name: "index_team_data_sources_on_data_source_id_and_team_id", unique: true
  end

  create_table "team_delegate_users", id: :serial, force: :cascade do |t|
    t.integer "team_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_team_delegate_users_on_team_id"
    t.index ["user_id"], name: "index_team_delegate_users_on_user_id"
  end

  create_table "teams", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "location"
    t.string "postcode"
    t.integer "z_team_status_id"
    t.string "telephone"
    t.string "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "division_id"
    t.integer "directorate_id"
    t.integer "delegate_approver"
  end

  create_table "user_notifications", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "notification_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "new", null: false
    t.index ["notification_id"], name: "index_user_notifications_on_notification_id"
    t.index ["user_id"], name: "index_user_notifications_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "telephone"
    t.string "mobile"
    t.string "location"
    t.text "notes"
    t.integer "z_user_status_id"
    t.string "job_title"
    t.string "username"
    t.integer "rejected_terms_count", default: 0
    t.string "grade"
    t.string "employment"
    t.date "contract_end_date"
    t.integer "directorate_id"
    t.integer "division_id"
    t.boolean "delegate_user"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "version_associations", id: :serial, force: :cascade do |t|
    t.integer "version_id"
    t.string "foreign_key_name", null: false
    t.integer "foreign_key_id"
    t.index ["foreign_key_name", "foreign_key_id"], name: "index_version_associations_on_foreign_key"
    t.index ["version_id"], name: "index_version_associations_on_version_id"
  end

  create_table "versions", id: :serial, force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.text "object_changes"
    t.integer "transaction_id"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
    t.index ["transaction_id"], name: "index_versions_on_transaction_id"
  end

  create_table "xml_type_enumeration_values", force: :cascade do |t|
    t.bigint "xml_type_id"
    t.bigint "enumeration_value_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["enumeration_value_id"], name: "index_xml_type_enumeration_values_on_enumeration_value_id"
    t.index ["xml_type_id"], name: "index_xml_type_enumeration_values_on_xml_type_id"
  end

  create_table "xml_types", force: :cascade do |t|
    t.string "name"
    t.string "annotation"
    t.integer "min_length"
    t.integer "max_length"
    t.string "pattern"
    t.string "restriction"
    t.string "attribute_name"
    t.integer "namespace_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "xsd_item_type_values", id: :serial, force: :cascade do |t|
    t.integer "xsd_item_type_id"
    t.string "enumeration_value", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["xsd_item_type_id"], name: "index_xsd_item_type_values_on_xsd_item_type_id"
  end

  create_table "xsd_item_types", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "xml_type", limit: 4000
    t.string "pattern_value", limit: 255
    t.integer "min_length"
    t.integer "max_length"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "xsd_item_xsd_types", id: :serial, force: :cascade do |t|
    t.integer "xsd_item_id"
    t.integer "xsd_item_type_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["xsd_item_id"], name: "index_xsd_item_xsd_types_on_xsd_item_id"
    t.index ["xsd_item_type_id"], name: "index_xsd_item_xsd_types_on_xsd_item_type_id"
  end

  create_table "xsd_items", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "item_number", limit: 50
    t.integer "min_occurs"
    t.integer "max_occurs"
    t.string "xml_type", limit: 255
    t.string "description", limit: 4000
    t.string "format", limit: 255
    t.string "schema_specification", limit: 50
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "xsd_schema_sections", id: :serial, force: :cascade do |t|
    t.integer "xsd_schema_id"
    t.integer "xsd_section_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["xsd_schema_id"], name: "index_xsd_schema_sections_on_xsd_schema_id"
    t.index ["xsd_section_id"], name: "index_xsd_schema_sections_on_xsd_section_id"
  end

  create_table "xsd_schemas", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "xsd_section_items", id: :serial, force: :cascade do |t|
    t.integer "xsd_section_id"
    t.integer "xsd_item_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["xsd_item_id"], name: "index_xsd_section_items_on_xsd_item_id"
    t.index ["xsd_section_id"], name: "index_xsd_section_items_on_xsd_section_id"
  end

  create_table "xsd_sections", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "min_occurs"
    t.integer "max_occurs"
    t.string "description", limit: 4000
    t.integer "sub_section_of"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "z_project_statuses", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_z_project_statuses_on_name", unique: true
  end

  create_table "z_team_statuses", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_z_team_statuses_on_name", unique: true
  end

  create_table "z_user_statuses", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_z_user_statuses_on_name", unique: true
  end

  create_table "ze_actiontype", primary_key: "ze_actiontypeid", id: :string, limit: 255, default: "1", force: :cascade do |t|
    t.string "shortdesc", limit: 64
    t.string "description", limit: 255
    t.datetime "startdate"
    t.datetime "enddate"
    t.bigint "sort"
    t.string "comments", limit: 255
  end

  create_table "ze_type", primary_key: "ze_typeid", id: :string, limit: 255, force: :cascade do |t|
    t.string "shortdesc", limit: 64
    t.string "description", limit: 255
    t.datetime "startdate"
    t.datetime "enddate"
    t.bigint "sort"
    t.string "comments", limit: 255
  end

  create_table "zprovider", primary_key: "zproviderid", id: :string, limit: 255, default: "1", force: :cascade do |t|
    t.string "shortdesc", limit: 128
    t.string "description", limit: 2000
    t.string "exportid", limit: 64
    t.datetime "startdate"
    t.datetime "enddate"
    t.bigint "sort"
    t.string "role", limit: 1
    t.integer "local_hospital", limit: 2, default: 0, null: false
    t.integer "breast_screening_unit", limit: 2, default: 0, null: false
    t.integer "historical", limit: 2, default: 0, null: false
    t.string "lpi_providercode", limit: 255
    t.string "zpostcodeid", limit: 255
    t.integer "linac", limit: 2, default: 0, null: false
    t.string "analysisid", limit: 255
    t.integer "nacscode", limit: 2
    t.string "nacs5id", limit: 5
    t.string "successorid", limit: 255
    t.string "local_registryid", limit: 5
    t.string "source", limit: 255
  end

  create_table "zuser", primary_key: "zuserid", id: :string, limit: 255, default: "1", force: :cascade do |t|
    t.string "shortdesc", limit: 64
    t.string "description", limit: 2000
    t.string "exportid", limit: 64
    t.datetime "startdate"
    t.datetime "enddate"
    t.bigint "sort"
    t.string "registryid", limit: 5
    t.string "qa_supervisorid", limit: 255
  end

  add_foreign_key "birth_data", "ppatients", on_delete: :cascade
  add_foreign_key "data_item_groups", "data_items"
  add_foreign_key "data_item_groups", "groups"
  add_foreign_key "death_data", "ppatients", on_delete: :cascade
  add_foreign_key "e_action", "e_batch", column: "e_batchid", primary_key: "e_batchid"
  add_foreign_key "e_action", "ze_actiontype", column: "e_actiontype", primary_key: "ze_actiontypeid"
  add_foreign_key "e_batch", "ze_type", column: "e_type", primary_key: "ze_typeid"
  add_foreign_key "e_batch", "zprovider", column: "provider", primary_key: "zproviderid"
  add_foreign_key "e_batch", "zprovider", column: "registryid", primary_key: "zproviderid"
  add_foreign_key "e_workflow", "ze_actiontype", column: "last_e_actiontype", primary_key: "ze_actiontypeid"
  add_foreign_key "e_workflow", "ze_actiontype", column: "next_e_actiontype", primary_key: "ze_actiontypeid"
  add_foreign_key "e_workflow", "ze_type", column: "e_type", primary_key: "ze_typeid"
  add_foreign_key "e_workflow", "zprovider", column: "provider", primary_key: "zproviderid"
  add_foreign_key "error_fingerprints", "error_fingerprints", column: "causal_error_fingerprintid", primary_key: "error_fingerprintid"
  add_foreign_key "memberships", "teams"
  add_foreign_key "memberships", "users"
  add_foreign_key "molecular_data", "ppatients", on_delete: :cascade
  add_foreign_key "node_categories", "categories"
  add_foreign_key "node_categories", "nodes"
  add_foreign_key "notifications", "projects"
  add_foreign_key "notifications", "teams"
  add_foreign_key "notifications", "users"
  add_foreign_key "ppatients", "e_batch", primary_key: "e_batchid"
  add_foreign_key "ppatients", "ppatient_rawdata", column: "ppatient_rawdata_id", primary_key: "ppatient_rawdataid"
  add_foreign_key "ppatients", "pseudonymisation_keys", column: "pseudonymisation_keyid", primary_key: "pseudonymisation_keyid"
  add_foreign_key "prescription_data", "ppatients", on_delete: :cascade
  add_foreign_key "project_attachments", "projects"
  add_foreign_key "project_comments", "project_data_source_items"
  add_foreign_key "project_comments", "projects"
  add_foreign_key "project_comments", "users"
  add_foreign_key "project_data_passwords", "projects"
  add_foreign_key "project_data_source_items", "data_source_items"
  add_foreign_key "project_data_source_items", "projects"
  add_foreign_key "project_end_uses", "end_uses"
  add_foreign_key "project_end_uses", "projects"
  add_foreign_key "project_memberships", "memberships"
  add_foreign_key "project_memberships", "projects"
  add_foreign_key "project_outputs", "outputs"
  add_foreign_key "project_outputs", "projects"
  add_foreign_key "projects", "teams"
  add_foreign_key "projects", "z_project_statuses"
  add_foreign_key "pseudonymisation_keys", "ze_type", column: "e_type", primary_key: "ze_typeid"
  add_foreign_key "pseudonymisation_keys", "zprovider", column: "provider", primary_key: "zproviderid"
  add_foreign_key "team_data_sources", "data_sources"
  add_foreign_key "team_data_sources", "teams"
  add_foreign_key "team_delegate_users", "teams"
  add_foreign_key "team_delegate_users", "users"
  add_foreign_key "user_notifications", "notifications"
  add_foreign_key "user_notifications", "users"
  add_foreign_key "xml_type_enumeration_values", "enumeration_values"
  add_foreign_key "xml_type_enumeration_values", "xml_types"
  add_foreign_key "xsd_item_type_values", "xsd_item_types"
  add_foreign_key "xsd_item_xsd_types", "xsd_item_types"
  add_foreign_key "xsd_item_xsd_types", "xsd_items"
  add_foreign_key "xsd_schema_sections", "xsd_schemas"
  add_foreign_key "xsd_schema_sections", "xsd_sections"
  add_foreign_key "xsd_section_items", "xsd_items"
  add_foreign_key "xsd_section_items", "xsd_sections"
  add_foreign_key "zuser", "zuser", column: "qa_supervisorid", primary_key: "zuserid"
end
