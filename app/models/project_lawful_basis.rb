# Join model for defining which GDPR articles apply for the purposes of processing the data
# released under a `Project`
class ProjectLawfulBasis < ApplicationRecord
  belongs_to :project
  belongs_to :lawful_basis, class_name: 'Lookups::LawfulBasis'

  has_paper_trail
end
