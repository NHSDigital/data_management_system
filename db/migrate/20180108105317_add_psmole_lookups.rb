# Add lookups for BRCA and other pseudonymised molecular data
class AddPsmoleLookups < ActiveRecord::Migration[5.0]
  def up
    ZeType.create(shortdesc:
                    'Pseudonymised Molecular Data') { |ze_type| ze_type.ze_typeid = 'PSMOLE' }
    # Create any missing registryid and providers of BRCA data
    %w(X25 RR8 RNZ RVJ RTD RX1 RCU RW3 RJ1).each do |zpid|
      Zprovider.valid_value?(zpid) || Zprovider.create { |zprovider| zprovider.zproviderid = zpid }
    end
  end
end
