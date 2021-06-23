class RemoveUpdateCasDeclarations < ActiveRecord::Migration[6.0]
  include MigrationHelper
  def change
    remove_lookup Lookups::CasDeclaration, 5, value: 'I have completed the relevant data access ' \
                                                     'forms for the ONS incidence dataset', sort: 5
    change_lookup Lookups::CasDeclaration, 2, { value: ' I confirm that I completed all the ' \
                                                       'Information Governance training on , as ' \
                                                       'deemed appropriate by my manager. This ' \
                                                       'includes completing appropriate ' \
                                                       'e-learning modules and other training in ' \
                                                       'the NCRAS Induction Pack. I agree to ' \
                                                       'update my Information Governance ' \
                                                       'training as directed by my manager.' },
                                                value: 'I confirm that I completed all the ' \
                                                       'Information Governance training as ' \
                                                       'deemed appropriate by my manager. This ' \
                                                       'includes completing appropriate ' \
                                                       'e-learning modules and other training in ' \
                                                       'the NCRAS Induction Pack. I agree to ' \
                                                       'update my Information Governance ' \
                                                       'training as directed by my manager.'
  end
end
