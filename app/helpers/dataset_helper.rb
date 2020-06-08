module DatasetHelper
  def dataset_type_options
    DatasetType.all.collect { |dt| [ dt.name, dt.id ] }.reverse
  end
end
