class ProjectEndUse < ApplicationRecord
  belongs_to :project
  belongs_to :end_use
end
