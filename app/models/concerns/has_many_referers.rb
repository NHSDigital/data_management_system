# Counterpart to `BelongsToReferent`; shared logic for `Project`s and `Amendment`s that may be
# referenced by `Contract`s, `DPIA`s or `Release`s.
module HasManyReferers
  extend ActiveSupport::Concern

  included do
    with_options as: :referent, dependent: :destroy do
      has_many :dpias, class_name: 'DataPrivacyImpactAssessment'
      has_many :contracts
      has_many :releases
    end
  end
end
