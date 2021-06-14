# plan.io 25873 - Make some datasets into cas_type of 'cas_defaults'
class UpdateCasTypeCasDefaultDatasets < ActiveRecord::Migration[6.0]
  include MigrationHelper
  def change
    ids = Dataset.where(name: ['DAHNO', 'NBOCAP', 'Linked HES OP', 'Linked HES A&E', 'CPES Wave 6',
                               'NPCA', 'LUCADA', 'NLCA', 'ONS Mortality', 'CPES Wave 1', 'SACT',
                               'Cancer registry', 'CPES Wave 2', 'BCCOM', 'PROMs pilot 2011-2012',
                               'Linked HES Admitted Care (IP)', 'Linked RTDS', 'CPES Wave 3',
                               'CPES Wave 5', 'Linked DIDs', 'Screening Programme - Cervical',
                               'Linked CWT (treatments only)', 'Screening Programme - Bowel',
                               'Screening Programme - Breast', 'CPES Wave 7', 'CPES Wave 4',
                               'CPES Wave 8']).pluck(:id)

    ids.each do |id|
      change_lookup Dataset, id, { cas_type: nil }, { cas_type: 1 }
    end
  end
end
