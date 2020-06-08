namespace :lookup do
  LOOKUP_FIXTURE_DIRECTORY = Rails.root.join('test', 'fixtures', 'lookups').freeze

  desc 'Creates/replaces a fixture file for a lookup model'
  task :create_fixture, [:klass] => [:environment, :create_lookup_fixture_dir] do |_task, args|
    fixtures = {}
    log      = ->(message) { puts "[#{Time.zone.now}]: #{message}" }
    klass    = "Lookups::#{args.klass.demodulize}".safe_constantize

    if klass.nil?
      log.call("Unknown lookup model #{args.klass}")
      abort
    end

    file   = LOOKUP_FIXTURE_DIRECTORY.join("#{klass.name.demodulize.underscore}.yml")
    action = file.exist? ? 'Refreshing' : 'Creating'

    log.call("#{action} fixture #{file}")

    klass.find_each do |instance|
      fixtures.store instance.id, instance.attributes
    end

    file.write <<~DATA
      # Created by `bin/rails lookup:create_fixture[#{args.klass}]` at #{Time.current}
      #{YAML.dump(fixtures)}
    DATA
  end

  task :create_lookup_fixture_dir do
    Dir.mkdir(LOOKUP_FIXTURE_DIRECTORY) unless Dir.exist?(LOOKUP_FIXTURE_DIRECTORY)
  end
end
