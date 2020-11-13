class PopulateCasDeclarationsLookup < ActiveRecord::Migration[6.0]
  include MigrationHelper

  class CasDeclaration < ApplicationRecord
    attribute :value, :text
    attribute :sort, :integer
  end

  def change
    add_lookup CasDeclaration, 1, sort: 1,
      value: 'I confirm that I understand the nature of the data to which I will have access, and the responsibilities that access to these data places on me. I understand that unauthorised disclosure of identifiable or potentially identifiable data will result in personal liability, and may be in breach of the Data Protection Act 2018. I undertake to act within the confidentiality policy of my employing organisation, within the confidentiality policy of the organisation hosting the Cancer Analysis System (NCRAS, PHE), and within the UKIACR policies on data disclosure.'

    add_lookup CasDeclaration, 2, sort: 2,
      value: ' I confirm that I completed all the Information Governance training on , as deemed appropriate by my manager. This includes completing appropriate e-learning modules and other training in the NCRAS Induction Pack. I agree to update my Information Governance training as directed by my manager.'

    add_lookup CasDeclaration, 3, sort: 3,
      value: 'I confirm that I will only access the CAS from locations listed in section 2. I confirm that I will inform the National Cancer Registration and Analysis Service through revision and resubmission of this form if I need to access the CAS from alternative locations, so the security of these locations can be assessed.'

    add_lookup CasDeclaration, 4, sort: 4,
      value: "I confirm that I need the 'level of access' and the selected datasets that require special permission identified in section 3.2 in order to deliver the work described in section 3.1. I confirm I will make sure that projects using Celtic data are discussed with the Celtic registries and that enough time is given to allow them the opportunity to comment on any output produced prior to its publication."

    add_lookup CasDeclaration, 5, sort: 5,
      value: 'I have completed the relevant data access forms for the ONS incidence dataset'
  end
end
