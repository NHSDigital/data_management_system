class ProjectEndUse < ApplicationRecord
  belongs_to :project
  belongs_to :end_use

  has_paper_trail
end
