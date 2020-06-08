module Export
  # Specification for a simple birth file
  # (CSV data with a header row, no special fields, leading zeros removed from agec)
  # To produce a simple extract, all that needs to be overridden is the #fields method.
  # Use filter='all' to get all records from a batch (including repeats)
  # or filter='new' to get only new records in a batch (excluding records sent before)
  # or filter='all_nhs' for all records with NHS numbers (including repeats)
  # or filter='new_nhs' for only new records with NHS numbers (excluding such records sent before)
  class BirthFileSimple < BirthFile
    include SimpleCsv
  end
end
