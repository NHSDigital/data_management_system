# birth record data
# - inflection for singular/plural changed in config/initializers/inflections.rb

module Pseudo
  class BirthData < ActiveRecord::Base
    belongs_to :ppatient # , dependent: :destroy

    validates :ppatient_id, presence: true
  end
end
