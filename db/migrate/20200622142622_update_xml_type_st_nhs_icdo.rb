class UpdateXmlTypeStNhsIcdo < ActiveRecord::Migration[6.0]
  def up
    XmlType.find_by(name: 'ST_NHS_ICDO').update(min_length: 4, pattern: nil)
  end

  def down
    XmlType.find_by(name: 'ST_NHS_ICDO').update(min_length: 5, pattern: '[a-zA-Z0-9]{5,7}')
  end
end
