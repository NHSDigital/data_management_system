# Add Barts R1H provider
class AddBartsProvider < ActiveRecord::Migration[6.1]
  def change
    Zprovider.create(zproviderid: 'R1H') unless Zprovider.exists?('R1H')
  end
end
