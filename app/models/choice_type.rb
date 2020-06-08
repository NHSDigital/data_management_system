# Types of choice we can make in xsd
class ChoiceType < ApplicationRecord
  has_many :choices, class_name: 'Nodes::Choice', foreign_key: 'choice_type_id',
                     inverse_of: :choice_type, dependent: :destroy

  OPTIONAL           = %w[optional_unbounded optional_or optional_and_or].freeze
  MANDATORY          = %w[mandatory_or mandatory_and_or mandatory_unbounded].freeze
  SINGLE             = %w[mandatory_or optional_or mandatory_multiple_or].freeze
  UNBOUNDED          = %w[optional_unbounded mandatory_unbounded].freeze
  MANDATORY_MULTIPLE = %w[mandatory_multiple_or mandatory_multiple_and_or].freeze

  def optional?
    name_in(OPTIONAL)
  end

  def unbounded?
    name_in(UNBOUNDED)
  end

  def mandatory?
    name_in(MANDATORY)
  end

  def mandatory_multiple?
    name_in(MANDATORY_MULTIPLE)
  end

  def single_choice?
    name_in(SINGLE)
  end

  private

  def name_in(types)
    types.include? name
  end
end
