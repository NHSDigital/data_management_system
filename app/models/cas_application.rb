class CasApplication < ApplicationRecord
  has_paper_trail

  def extra_datasets
    # retrieve as an array
    read_attribute(:extra_datasets).to_s.split(',')
  end

  def extra_datasets=(value)
    # store as a string seperated by comma
    write_attribute(:extra_datasets, [value].join(','))
  end

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
end
