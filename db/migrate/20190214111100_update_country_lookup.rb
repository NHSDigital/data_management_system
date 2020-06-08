class UpdateCountryLookup < ActiveRecord::Migration[5.2]
  include MigrationHelper

  def change
    change_lookup Lookups::Country, 'XKU', { value: 'UNITED KINGDOM ⁯' }, { value: 'UNITED KINGDOM' }
  end
end
