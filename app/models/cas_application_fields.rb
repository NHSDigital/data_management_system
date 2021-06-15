# model for cas application fields associated with a cas project
class CasApplicationFields < ApplicationRecord
  belongs_to :project
  has_paper_trail

  validate :all_declarations_must_be_agreed

  def declaration=(value)
    # store as a string seperated by comma
    write_attribute(:declaration, [value].join(','))
  end

  def declaration_choices
    # the choices in the format of { id => Yes/No }
    # e.g. { '1' => 'No', '2' => 'Yes' }
    return {} if declaration.blank?
    declaration.split(',').map do |choice|
      if match = choice.match(/^(\d+)(Yes|No)$/)
        [match[1], match[2]]
      end
    end.compact.to_h
  end

  def all_declarations_must_be_agreed
    return if declaration_choices.size == Lookups::CasDeclaration.count &&
              declaration_choices.values.all?('Yes')

    errors.add :declaration, :must_all_be_yes
  end
end
