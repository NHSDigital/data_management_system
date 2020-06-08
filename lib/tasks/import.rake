require 'highline/import'

namespace :import do
  desc 'Import MBIS Death data'
  task death: [:environment, 'pseudo:keys:load'] do
    death_file = ENV['fname']
    keep = ENV['keep'] =~ /\A[Yy]/ # Use keep=Y to keep failed imports and not rollback.
    raise('Expected fname') if death_file.blank?
    # TODO: ask for e_batch date references
    _e_batch = Import::Helpers::RakeHelper::FileImporter.
               import_mbis_and_rollback_failures(death_file, 'PSDEATH', keep)
  end

  desc 'Import MBIS Birth data'
  task birth: [:environment, 'pseudo:keys:load'] do
    birth_file = ENV['fname']
    keep = ENV['keep'] =~ /\A[Yy]/ # Use keep=Y to keep failed imports and not rollback.
    raise('Expected fname') if birth_file.blank?
    # TODO: ask for e_batch date references
    _e_batch = Import::Helpers::RakeHelper::FileImporter.
               import_mbis_and_rollback_failures(birth_file, 'PSBIRTH', keep)
  end
end
