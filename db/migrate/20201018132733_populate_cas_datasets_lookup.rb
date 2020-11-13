class PopulateCasDatasetsLookup < ActiveRecord::Migration[6.0]
  include MigrationHelper

  class CasDataset < ApplicationRecord
    attribute :value, :text
    attribute :sort, :integer
  end

  def change
    add_lookup CasDataset, 1, sort: 1,
      value: '* ONS mortality tables (all available)Schema: ONS2011, 2012, 2013, 2014 etc...'

    add_lookup CasDataset, 2, sort: 2,
      value: 'Cancer Waiting Times referrals'

    add_lookup CasDataset, 3, sort: 3,
      value: 'Cancer Waiting Times Legacy data'

    add_lookup CasDataset, 4, sort: 4,
      value: 'Anonymised Patient Reported Outcomes Measures(bowel, bladder, pilot 2011 and 2012) Schema: PROMS'

    add_lookup CasDataset, 5, sort: 5,
      value: 'Patient Reported Outcomes Measures (bowel, bladder, pilot 2011, 2012) Schema: PROMS'

    add_lookup CasDataset, 6, sort: 6,
      value: 'Patient Reported Outcomes Measures (Gynaecological cancers) Schema: PROMS'

    add_lookup CasDataset, 7, sort: 7,
      value: 'Biobank indicator'

    add_lookup CasDataset, 8, sort: 8,
      value: 'Prescriptions sample Schema: PRESCRIPTIONSAMPLE, PRESCRIPTION2015'

    add_lookup CasDataset, 9, sort: 9,
      value: 'Mosaic etc... Schema: Mosaic2017, Mosaic2018 etc...'
  end
end
