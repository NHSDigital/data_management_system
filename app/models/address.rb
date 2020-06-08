# Polymorphic
class Address < ApplicationRecord
  belongs_to :addressable, polymorphic: true
  belongs_to :country, class_name: 'Lookups::Country', optional: true

  delegate :value, to: :country, prefix: true
end
