class PopulateClosureReasonsTable < ActiveRecord::Migration[5.2]
  include MigrationHelper

  class ClosureReason < ApplicationRecord
    attribute :value, :string
  end

  def change
    add_lookup ClosureReason, 1,  value: 'Unresponsive'
    add_lookup ClosureReason, 2,  value: 'Duplicate'
    add_lookup ClosureReason, 3,  value: 'Proceeding to application'
    add_lookup ClosureReason, 4,  value: 'Referral to different data controller'
    add_lookup ClosureReason, 5,  value: 'Freedom of Information Act (FOIA) Request - redirected'
    add_lookup ClosureReason, 6,  value: 'Subject Access Request (SAR) - redirected'
    add_lookup ClosureReason, 7,  value: 'Data is not available'
    add_lookup ClosureReason, 8,  value: 'Proceeding to amendment'
    add_lookup ClosureReason, 9,  value: 'Applicant withdrew'
    add_lookup ClosureReason, 10, value: 'Not feasible'
    add_lookup ClosureReason, 11, value: 'Statisitical enquiry - redirected'
  end
end
