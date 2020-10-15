class AddMissingGermlineProvidercode < ActiveRecord::Migration[6.0]
  def up
    # Create any missing providers of BRCA data
    Zprovider.create(zproviderid: 'RP4') unless Zprovider.exists?('RP4')
  end

  # Do nothing, we want to keep these providercodes
  def down; end
end
