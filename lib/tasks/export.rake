require 'highline/import'

def export_mbis_birth_or_death(e_type)
  # TODO: other options to export e_batch by date reference and e_type, or e_batchid
  raise('Expected fname') if ENV['fname'].blank?
  fname = 'extracts/' + ENV['fname']
  fname2 = SafePath.new('mbis_data').join(fname)
  FileUtils.mkdir_p(Pathname.new(fname2).parent)
  basedir = ENV['basedir'].present? ? 'extracts/' + ENV['basedir'] : Pathname.new(fname).parent.to_s
  raise('Expected klass') unless ENV['klass']&.start_with?('Export::')
  original_filename = ENV['original_filename']
  raise('Expected original_filename') if original_filename.blank?
  raise('Invalid limit') if ENV['limit'].present? && ENV['limit'].to_i.to_s != ENV['limit']
  limit = ENV['limit'].to_i if ENV['limit'].present?
  klass = ENV['klass'].constantize # e.g. Export::DelimitedFile, Export::CancerMortalityFile
  pdp = if ENV['project_name'] # Generate encrypted output
          raise 'Invalid output filename' if fname =~ /[.]zip\Z/i
          Export::Helpers::RakeHelper::EncryptOutput.find_project_data_password(
            ENV['project_name'], ENV['team_name']
          )
          # implicitly 'else nil'
        end

  e_batch = EBatch.where(e_type: e_type, provider: 'XDC04', registryid: 'XDC04',
                         original_filename: original_filename).first
  raise('Batch not found') unless e_batch
  if limit
    max_id = e_batch.ppatients.limit(limit).order(:id).pluck(:id).last
    ppats = e_batch.ppatients.where('ppatients.id <= ?', max_id)
  else
    ppats = e_batch.ppatients
  end
  # TODO: Check for memory leaks on export
  # ??? Add progress monitoring block parameter
  rows = if ENV['filter'].present?
           klass.new(fname2, e_batch.e_type, ppats, ENV['filter']).export
         else
           klass.new(fname2, e_batch.e_type, ppats).export
         end
  puts "Created file with #{rows} records using #{klass.name}"
  return unless pdp # Optionally encrypt output
  fn_zip = fname.gsub(/[.][^.]*\Z/, '.zip')
  Export::Helpers::RakeHelper::EncryptOutput.compress_and_encrypt_zip(pdp, basedir, fn_zip, fname)
end

namespace :export do
  desc 'Export MBIS Death data'
  task death: [:environment, 'pseudo:keys:load'] do
    export_mbis_birth_or_death('PSDEATH')
  end

  desc 'Export MBIS Birth data'
  task birth: [:environment, 'pseudo:keys:load'] do
    export_mbis_birth_or_death('PSBIRTH')
  end
end
