class RemoveOldStyleMbisTableSpecs < ActiveRecord::Migration[6.0]
  def up
    Dataset.table_spec.where(name: datasets).each(&:destroy)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def datasets
    ['Births Gold Standard', 'Death Transaction', 'Deaths Gold Standard', 'Birth Transaction']
  end
end
