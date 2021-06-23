# plan.io 25866 - set ONS incedence dataset cas_type to nil
class UpdateOnsIncedenceDatasetCasType < ActiveRecord::Migration[6.0]
  include MigrationHelper
  def change
    id = Dataset.find_by(name: 'ONS incidence tables (all available)Schema: ONS1971_1994, 1989, ' \
                               '2010, 2011, 2012, 2013, 2014 ONS short declaration form ' \
                               'completed.').id
    change_lookup Dataset, id, { cas_type: 2 }, { cas_type: nil }
  end
end
