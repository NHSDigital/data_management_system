# lifted mostly from rubyzip gem examples
class SchemaPack
  attr_accessor :dataset_version, :version_previous, :temporary_file

  def initialize(version, version_previous = nil, temporary_file = nil)
    @dataset_version = version
    @version_previous = version_previous
    @temporary_file = temporary_file

    build
  end

  def build
    Zip::File.open(filename, create: true) do |zipfile|
      xsd = Xsd::SchemaFiles.new(dataset_version, zipfile)
      xsd.components.each(&:save_file)
      # TODO: previous dataset version front end selection
      # TODO: Change Log
      schema_browser(zipfile)
      change_log(zipfile)
    end
  end

  def schema_browser(zipfile)
    browser = SchemaBrowser::Builder.new(dataset_version.dataset, dataset_version,
                                         version_previous, zipfile)
    browser.components.each(&:save_file)
  end

  def change_log(zipfile)
    return if version_previous.nil?
    
    changelog = Nodes::ChangeLog.new(dataset_version.dataset, version_previous,
                                     dataset_version, false, zipfile)
    changelog.save_fil
  end
  
  def filename
    return temporary_file.path unless temporary_file.nil?

    zip_file_path.join("#{dataset_version.name}_v#{dataset_version.schema_version_format}.zip")
  end

  # Hook for test
  def zip_file_path
    Rails.root.join('tmp')
  end
end
