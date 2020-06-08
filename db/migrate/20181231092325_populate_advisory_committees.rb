class PopulateAdvisoryCommittees < ActiveRecord::Migration[5.2]
  include MigrationHelper

  class AdvisoryCommittee < ApplicationRecord
    attribute :value, :string
  end

  def change
    add_lookup AdvisoryCommittee, 1,  value: 'NHS Abdominal Aortic Aneurysm (AAA) Programme RAC'
    add_lookup AdvisoryCommittee, 2,  value: 'NHS Bowel Cancer Screening (BCSP) Programme RAC'
    add_lookup AdvisoryCommittee, 3,  value: 'NHS Breast Screening (BSP) Programme RAC'
    add_lookup AdvisoryCommittee, 4,  value: 'NHS Cervical Screening (CSP) Programme RAC'
    add_lookup AdvisoryCommittee, 5,  value: 'NHS Diabetic Eye Screening (DES) Programme RAC'
    add_lookup AdvisoryCommittee, 6,  value: 'NHS Fetal Anomaly Screening Programme (FASP) RAC'
    add_lookup AdvisoryCommittee, 7,  value: 'NHS Infectious Diseases in Pregnancy Screening (IDPS) Programme RAC'
    add_lookup AdvisoryCommittee, 8,  value: 'NHS Newborn and Infant Physical Examination (NIPE) Screening Programme RAC'
    add_lookup AdvisoryCommittee, 9,  value: 'NHS Newborn Blood Spot (NBS) Screening Programme RAC'
    add_lookup AdvisoryCommittee, 10, value: 'NHS Newborn Hearing Screening Programme (NHSP) RAC'
    add_lookup AdvisoryCommittee, 11, value: 'NHS Sickle Cell and Thalassaemia (SCT) Screening Programme RAC'
  end
end
