namespace :xsd do
  # Destroy schema related datasets only, repopulates data and builds schema and samples
  task all: %i[seed previous_node_ids build_schema_and_examples]

  # Destroy schema related datasets only, repopulates data and builds schema and samples to zip file
  task all_zip: %i[seed previous_node_ids build_schema_zip_files]

  task build_schema_zip_files: :environment do
    Dataset.where(name: %w[COSD COSD_Pathology SACT MultipleRecordTypeDataset]).each do |d|
      d.dataset_versions.pluck(:semver_version).each do |v|
        print "Saving Dataset: #{d.name}, Version: #{v} to zip\n"
        d.save_to_zip(v)
      end
    end
  end

  task v9: :environment do
    started = Time.zone.now
    puts "STARTED => #{started}"
    Dataset.where(name: %w[COSD]).each do |dataset|
      dataset.dataset_versions.each do |v|
        next unless v.semver_version.match? /9[-\.]0/

        print "Building Dataset: #{v.name} Version: #{v.semver_version}\n"
        dataset.to_multi_xsd(v.semver_version)
      end
    end
    Dataset.where(name: %w[COSD_Pathology]).each do |dataset|
      dataset.dataset_versions.each do |v|
        next unless v.semver_version.match? /4[-\.]0/

        print "Building Dataset: #{v.name} Version: #{v.semver_version}\n"
        dataset.to_multi_xsd(v.semver_version)
      end
    end
    print "#{started}\n"
    finished = Time.zone.now
    print "FINISHED => #{finished}\n"
    print "DURATION => #{(finished - started).round(2)} SECONDS\n\n"
  end

  task build_schema_and_examples: :environment do
    started = Time.zone.now
    puts "STARTED => #{started}"
    # create tmp folders if they don't exist
    unless File.exist? Rails.root.join('tmp', 'schema')
      FileUtils.mkdir_p(Rails.root.join('tmp', 'schema'))
    end
    unless File.exist? Rails.root.join('tmp', 'sample_xml')
      FileUtils.mkdir_p(Rails.root.join('tmp', 'sample_xml'))
    end
    Dataset.where(name: %w[COSD COSD_Pathology SACT MultipleRecordTypeDataset]).each do |dataset|
      dataset.dataset_versions.each do |v|
        # Only building dataset versions to build change log
        next if legacy_schema?(dataset, v)

        print "Building Dataset: #{v.name} Version: #{v.semver_version}\n"
        files = Xsd::SchemaFiles.new(v)
        files.components.each(&:save_file)
      end
    end
    print "#{started}\n"
    finished = Time.zone.now
    print "FINISHED => #{finished}\n"
    print "DURATION => #{(finished - started).round(2)} SECONDS\n\n"
  end

  task build_multi_files: :environment do
    started = Time.zone.now
    puts "STARTED => #{started}"
    Dataset.where(name: %w[COSD COSD_Pathology SACT MultipleRecordTypeDataset]).each do |dataset|
      dataset.dataset_versions.each do |v|
        # Only building dataset versions to build change log
        next if legacy_schema?(dataset, v)

        print "Building Dataset: #{v.name} Version: #{v.semver_version}\n"
        dataset.to_multi_xsd(v.semver_version)
      end
    end
    print "#{started}\n"
    finished = Time.zone.now
    print "FINISHED => #{finished}\n"
    print "DURATION => #{(finished - started).round(2)} SECONDS\n\n"
  end

  task build_sample_xml_files: :environment do
    started = Time.zone.now
    puts "STARTED => #{started}"
    Dataset.where(name: %w[COSD COSD_Pathology SACT MultipleRecordTypeDataset]).each do |dataset|
      dataset.dataset_versions.each do |v|
        next if legacy_schema?(dataset, v)

        puts "Building Sample: #{dataset.name} Version: #{v.semver_version}"
        %w[sample_items sample_choices].each { |sample_type| v.build_sample_xml(sample_type) }
      end
    end
    finished = Time.zone.now
    print "FINISHED => #{finished}\n"
    print "DURATION => #{(finished - started).round(2)} SECONDS\n\n"
  end

  def legacy_schema?(dataset, version)
    (dataset.name == 'COSD' && (version.semver_version.match? /8[-\.]1/ ))||
      (dataset.name == 'COSD_Pathology' && (version.semver_version.match? /3[-\.]0/ ))
  end

  task save_schema_pack_latest: :environment do
    dataset = Dataset.find_by(name: ENV['DATASET'] == 'COSD' ? 'COSD' : 'COSD_Pathology')
    version = ENV['DATASET'] == 'COSD' ? '9.0' : '4.1.1'

    # For Change Log
    version_previous = ENV['DATASET'] == 'COSD' ? '8.1' : '4.1'

    started = Time.now.getlocal
    print "STARTED => #{started}\n"
    save_to_zip(dataset, version, version_previous)
    finished = Time.now.getlocal
    print "FINISHED => #{finished}\n"
    print "DURATION => #{(finished - started).round(2)} seconds\n"
    print "Done\n"
  end

  def save_to_zip(dataset, version, version_previous)
    check_folder_path
    fname = "#{Date.current.strftime('%Y%m%d')}_#{Time.now.getlocal.strftime('%H%M%S')}_"
    d_version = dataset.dataset_versions.find_by(semver_version: version)
    d_version_previous = dataset.dataset_versions.find_by(semver_version: version_previous)
    fname.concat "#{dataset.name}_v#{d_version.schema_version_format}.zip"
    filename = Rails.root.join('tmp', 'schema_packs').join(fname)
    Zip::File.open(filename, Zip::File::CREATE) do |zipfile|
      print "Generating Schema Files...\n"
      schema_files = Xsd::SchemaFiles.new(d_version, zipfile)
      schema_files.components.each(&:save_file)
      print "Generating Schema Browser...\n"
      browser = SchemaBrowser::Builder.new(dataset, d_version, d_version_previous, zipfile)
      browser.components.each(&:save_file)
      print "Generating Change Log...\n"
      generate_change_log(dataset, d_version_previous, d_version, zipfile)
    end
  end

  # TODO: move to browser builder
  def add_browser_templates(zipfile)
    zip_file_path = 'schema_browser/Template/'
    folder_to_copy = Rails.root.join('lib', 'schema_browser', 'Template')
    z = ZipFolderCopy.new(folder_to_copy, zipfile, zip_file_path)
    z.write
  end

  def generate_change_log(dataset, version_previous, version, zipfile)
    return if version_previous.nil?

    changelog = Nodes::ChangeLog.new(dataset, version_previous, version, false, zipfile)
    changelog.save_file
  end

  task save_schema_pack: :environment do
    # dataset          = ask('Dataset Name:')
    # version          = ask('Dataset Version:')
    # version_previous = ask('Dataset Version previous to diff:')
    dataset          = 'COSD'
    version          = '9.0.1'
    version_previous = '9.0'

    dataset          = Dataset.find_by(name: dataset)
    raise "No dataset found for #{dataset_name}"             if dataset.nil?

    started = Time.now.getlocal
    print "STARTED => #{started}\n"
    save_to_zip(dataset, version, version_previous)
    finished = Time.now.getlocal
    print "FINISHED => #{finished}\n"
    print "DURATION => #{(finished - started).round(2)} seconds\n"
    print "Done\n"
  end

  def check_folder_path
    tmp_folder = Rails.root.join('tmp', 'schema_packs')
    return if Dir.exist?(tmp_folder)

    FileUtils.mkdir_p(tmp_folder)
  end
end
