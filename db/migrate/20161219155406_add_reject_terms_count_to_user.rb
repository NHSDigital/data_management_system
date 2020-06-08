class AddRejectTermsCountToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :rejected_terms_count, :integer, default: 0
  end
end
