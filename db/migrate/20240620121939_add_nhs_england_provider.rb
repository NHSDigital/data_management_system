class AddNhsEnglandProvider < ActiveRecord::Migration[6.1]
  def change
     Zprovider.create(zproviderid: 'X26') unless Zprovider.exists?('X26')
  end
end
