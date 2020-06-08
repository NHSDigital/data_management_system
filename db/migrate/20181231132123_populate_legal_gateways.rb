class PopulateLegalGateways < ActiveRecord::Migration[5.2]
  include MigrationHelper

  class LegalGateway < ApplicationRecord
    attribute :value, :string
  end

  def change
    add_lookup LegalGateway, 1, value: 'Informed Patient Consent'
    add_lookup LegalGateway, 2, value: 'S42(4) of the SRSA 2007 Amended by s287 of the Health and Social Care Act 2012'
    add_lookup LegalGateway, 3, value: 'Approved Researched Accreditation'
  end
end
