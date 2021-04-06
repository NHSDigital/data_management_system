require 'highline/import'
# require 'import/colorectal/core/colorectal'
namespace :import do
  desc 'Import Colorectal data'
  task colorectal: [:environment] do
    colorectal_file = ENV['fname']
    colo_prov_code  = ENV['prov_code']
    raise('Expected fname')                     if colorectal_file.blank?
    raise('Expected provider code (prov_code)') if colo_prov_code.blank?

    file_name = SafePath.new('pseudonymised_data').join(colorectal_file)
    e_batch = EBatch.create(original_filename: colorectal_file,
                            e_type:            'PSMOLE',
                            provider:          colo_prov_code,
                            registryid:        colo_prov_code)

    Import::Colorectal::Core::ColorectalMainlineImporter.new(file_name, e_batch).load
  end
end
