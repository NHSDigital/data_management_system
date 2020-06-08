# Set the UI date format
[Date, Time].map do |klass|
  klass::DATE_FORMATS[:ui]           = '%d/%m/%Y'
  klass::DATE_FORMATS[:ui_with_time] = '%d/%m/%Y %R'
end
