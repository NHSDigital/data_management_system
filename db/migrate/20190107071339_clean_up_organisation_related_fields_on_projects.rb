class CleanUpOrganisationRelatedFieldsOnProjects < ActiveRecord::Migration[5.2]
  def change
    remove_foreign_key :projects, column: :sponsor_country_id
    remove_column :projects, :sponsor_name
    remove_column :projects, :sponsor_department
    remove_column :projects, :sponsor_add1
    remove_column :projects, :sponsor_add2
    remove_column :projects, :sponsor_city
    remove_column :projects, :sponsor_postcode
    remove_column :projects, :sponsor_country_id

    remove_foreign_key :projects, column: :funder_country_id
    remove_column :projects, :funder_name
    remove_column :projects, :funder_department
    remove_column :projects, :funder_add1
    remove_column :projects, :funder_add2
    remove_column :projects, :funder_city
    remove_column :projects, :funder_postcode
    remove_column :projects, :funder_country_id

    remove_foreign_key :projects, column: :data_processor_country_id
    remove_column :projects, :data_processor_name
    remove_column :projects, :data_processor_department
    remove_column :projects, :data_processor_add1
    remove_column :projects, :data_processor_add2
    remove_column :projects, :data_processor_city
    remove_column :projects, :data_processor_postcode
    remove_column :projects, :data_processor_country_id
  end
end
