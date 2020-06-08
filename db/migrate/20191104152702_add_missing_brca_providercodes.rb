# Add missing BRCA providercodes
class AddMissingBrcaProvidercodes < ActiveRecord::Migration[6.0]
  def up
    # Create any missing providers of BRCA data
    %w[R0A RJ7 RPY RTH].each do |zpid|
      Zprovider.create(zproviderid: zpid) unless Zprovider.exists?(zpid)
    end
  end

  # Do nothing, we want to keep these providercodes
  def down; end
end
