# Project Classfications relationship
class ProjectClassification < ApplicationRecord
  belongs_to :project
  belongs_to :classification

  has_paper_trail
end
