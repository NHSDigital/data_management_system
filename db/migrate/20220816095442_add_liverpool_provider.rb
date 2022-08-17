# Add REP Liverpool provider
class AddLiverpoolProvider < ActiveRecord::Migration[6.0]
  def up
    # Create any missing providers of BRCA data
    Zprovider.create(zproviderid: 'REP') unless Zprovider.exists?('REP')
  end

  # Do nothing, we want to keep these providercodes
  def down; end
end
