module Export
  # Specification for a simple death file
  # (CSV data with a header row, no special fields, leading zeros removed from agec)
  # To produce a simple extract, all that needs to be overridden is the #fields method.
  # Use filter='all' to get all records from a batch (including repeats)
  # or filter='new' to get only new records in a batch (excluding records sent before)
  # or filter='all_nhs' for all records with NHS numbers (including repeats)
  # or filter='new_nhs' for only new records with NHS numbers (excluding such records sent before)
  class DeathFileSimple < DeathFile
    include SimpleCsv

    private

    # Emit the value for a particular field, including extract-specific tweaks
    # TODO: Refector with CancerMortalityFile, into DeathFile
    def extract_field(ppat, field)
      # Special fields not in the original spec
      val = super(ppat, field)
      case field
      when 'agec' # Remove leading zeros
        val = val.to_i.to_s if val.present?
      end
      val
    end
  end
end
