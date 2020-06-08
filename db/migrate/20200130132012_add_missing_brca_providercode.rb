# Add missing BRCA providercode
class AddMissingBrcaProvidercode < ActiveRecord::Migration[6.0]
  def up
    Zprovider.create(zproviderid: 'R1K') unless Zprovider.exists?('R1K')
  end

  # Do nothing, we want to keep these providercodes
  def down; end
end
