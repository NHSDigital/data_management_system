# model for cas application fields associated with a cas project
class CasApplicationFields < ApplicationRecord
  belongs_to :project
  has_paper_trail

  validate :reason_justification_must_be_populated_if_level_1_selected
  validate :extra_datasets_rationale_must_be_populated_if_extra_datasets
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

  def reason_justification_must_be_populated_if_level_1_selected
    return if reason_justification.present?
    return unless project.project_datasets.any? do |pd|
                    pd.project_dataset_levels.any? do |pdl|
                      pdl.access_level_id == 1 && pdl.selected == true
                    end
                  end

    errors.add :reason_justification, :must_be_present_if_level_one
  end

  def extra_datasets_rationale_must_be_populated_if_extra_datasets
    return if extra_datasets_rationale.present?
    return unless project.project_datasets.any? do |pd|
                    pd.dataset.cas_extras? && pd.project_dataset_levels.any? do |pdl|
                      pdl.selected == true
                    end
                  end

    errors.add :extra_datasets_rationale, :must_be_present_if_extra_dataset_selected
  end

  def all_declarations_must_be_agreed
    return if declaration_choices.size == Lookups::CasDeclaration.count &&
              declaration_choices.values.all?('Yes')

    errors.add :declaration, :must_all_be_yes
  end
end
