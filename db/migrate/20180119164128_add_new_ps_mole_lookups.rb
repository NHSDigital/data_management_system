class AddNewPsMoleLookups < ActiveRecord::Migration[5.0]
  def up
    # Create any missing registryid and providers of BRCA data
    %w(RGT RQ3).each do |zpid|
      Zprovider.valid_value?(zpid) || Zprovider.create { |zprovider| zprovider.zproviderid = zpid }
    end
  end
end
