# patient prescription table
# - inflection for singular/plural changed in config/initializers/inflections.rb

module Pseudo
  class PrescriptionData < ActiveRecord::Base
    belongs_to :ppatient

    validates :part_month, presence: true
  end
end
