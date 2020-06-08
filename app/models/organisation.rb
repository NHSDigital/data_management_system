class Organisation < ApplicationRecord
  belongs_to :country,           class_name: 'Lookups::Country', optional: true
  belongs_to :organisation_type, class_name: 'Lookups::OrganisationType'

  has_many :teams, dependent: :destroy
  has_many :addresses, as: :addressable
  accepts_nested_attributes_for :addresses, reject_if: :all_blank,
                                            allow_destroy: true, update_only: :true
  has_paper_trail

  validates :name, presence: true
  validates :organisation_type_other, presence: true, if: -> {
    organisation_type == Lookups::OrganisationType.other
  }
  validates :organisation_type_other, absence: true, if: -> {
    organisation_type != Lookups::OrganisationType.other
  }

  before_save :nullify_empty_strings

  delegate :value, to: :country, prefix: true

  class << self
    def search(params)
      filters = []
      filters << name_filter(params[:name])

      filters.compact!
      filters.inject(all) { |chain, filter| chain.where(filter) }
    end

    private

    def name_filter(text)
      arel_table[:name].matches("%#{text.strip}%") if text.present?
    end
  end

  def organisation_type_value
    organisation_type_other || organisation_type.value
  end

  private

  def nullify_empty_strings
    attributes.each do |name, value|
      self[name] = nil if value.blank?
    end
  end
end
