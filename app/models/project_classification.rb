# Project Classfications relationship
class ProjectClassification < ApplicationRecord
  belongs_to :project
  belongs_to :classification
end
