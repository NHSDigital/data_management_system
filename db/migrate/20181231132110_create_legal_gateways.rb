class CreateLegalGateways < ActiveRecord::Migration[5.2]
  def change
    create_table :legal_gateways do |t|
      t.string :value
      t.timestamps
    end
  end
end
