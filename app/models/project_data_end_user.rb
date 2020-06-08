# For Storing End users of a Project
class ProjectDataEndUser < ApplicationRecord
  belongs_to :project

  has_paper_trail
end
