require 'highline/import'

namespace :import do
  desc <<~SYNTAX
    Import MBIS Death data
    Usage:
      bin/rake import:death fname='deaths/MBISWEEKLY_Deaths_D171028.txt' [keep=Y] [ignore_footer=Y]
      Use keep=Y to keep failed imports and not rollback.
      Use ignore_footer=Y to import files missing a footer row
  SYNTAX
  task death: [:environment, 'pseudo:keys:load'] do
    death_file = ENV['fname']
    keep = ENV['keep'] =~ /\A[Yy]/ # Use keep=Y to keep failed imports and not rollback.
    # Use ignore_footer=Y to import files missing a footer row
    ignore_footer = ENV['ignore_footer'] =~ /\A[Yy]/
    raise('Expected fname') if death_file.blank?
    # TODO: ask for e_batch date references
    _e_batch = Import::Helpers::RakeHelper::FileImporter.
               import_mbis_and_rollback_failures(death_file, 'PSDEATH',
                                                 keep: keep, ignore_footer: ignore_footer)
  end

  desc <<~SYNTAX
    Import MBIS Birth data
    Usage:
      bin/rake import:birth fname='births/MBISWEEKLY_Births_B171028.txt' [keep=Y] [ignore_footer=Y]
      Use keep=Y to keep failed imports and not rollback.
      Use ignore_footer=Y to import files missing a footer row
  SYNTAX
  task birth: [:environment, 'pseudo:keys:load'] do
    birth_file = ENV['fname']
    keep = ENV['keep'] =~ /\A[Yy]/ # Use keep=Y to keep failed imports and not rollback.
    # Use ignore_footer=Y to import files missing a footer row
    ignore_footer = ENV['ignore_footer'] =~ /\A[Yy]/
    raise('Expected fname') if birth_file.blank?
    # TODO: ask for e_batch date references
    _e_batch = Import::Helpers::RakeHelper::FileImporter.
               import_mbis_and_rollback_failures(birth_file, 'PSBIRTH',
                                                 keep: keep, ignore_footer: ignore_footer)
  end
end
