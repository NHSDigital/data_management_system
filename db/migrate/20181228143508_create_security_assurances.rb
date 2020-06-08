class CreateSecurityAssurances < ActiveRecord::Migration[5.2]
  def change
    create_table :security_assurances do |t|
      t.string :value
      t.timestamps
    end
  end
end
