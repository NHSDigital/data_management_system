module Pseudo
  class Molecular < Ppatient
    belongs_to :ppatient, dependent: :destroy
  end
end
