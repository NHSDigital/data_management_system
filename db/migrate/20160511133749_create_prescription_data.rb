class CreatePrescriptionData < ActiveRecord::Migration[5.0]
  # - inflection for singular/plural changed in config/initializers/inflections.rb
  def change
    create_table :prescription_data, id: false do |t|
      t.primary_key  :prescription_dataid
      t.references   :ppatient, index: true # i.e. belongs_to (alias)

      t.text    :part_month         #  must have format YYYY-MM (e.g. 2013-08) or YYYYMM (e.g. 201308)
      t.date    :presc_date
      t.text    :presc_postcode
      t.text    :pco_code
      t.text    :pco_name
      t.text    :practice_code
      t.text    :practice_name
      t.text    :nic
      t.text    :presc_quantity
      t.integer :item_number
      t.text    :unit_of_measure
      t.integer :pay_quantity
      t.text    :drug_paid
      t.text    :bnf_code
      t.integer :pat_age
      t.text    :pf_exempt_cat
      t.text    :etp_exempt_cat
      t.text    :etp_indicator
    end

    add_index :prescription_data, :bnf_code   # for matching against BNF codes in another table
  end
end
