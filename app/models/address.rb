# Polymorphic
class Address < ApplicationRecord
  belongs_to :addressable, polymorphic: true
  belongs_to :country, class_name: 'Lookups::Country', optional: true

  delegate :value, to: :country, prefix: true

  validates :default_address, uniqueness: { scope: %i[addressable_id addressable_type] },
                              if: proc { |address| address.default_address == true }
end
