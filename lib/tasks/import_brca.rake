require 'highline/import'
# require 'import/brca/core/brca.rb'
namespace :import do
  desc 'Import BRCA data'
  task brca: [:environment] do
    brca_file = ENV['fname']
    prov_code  = ENV['prov_code']
    raise('Expected fname')                     if brca_file.blank?
    raise('Expected provider code (prov_code)') if prov_code.blank?

    file_name = SafePath.new('pseudonymised_data').join(brca_file)
    e_batch = EBatch.create(original_filename: brca_file,
                            e_type:            'PSMOLE',
                            provider:          prov_code,
                            registryid:        prov_code)

    Import::Brca::Core::BrcaMainlineImporter.new(file_name, e_batch).load
  end
end
