namespace :ci do
  desc 'Setup CI stack, integrations, etc'
  task setup: [
    :environment,
    'ci:rugged:setup',
    'ci:slack:setup',
    'ci:prometheus:setup'
  ]

  desc 'Migrate the database'
  task migrate: [
    'db:migrate'
  ]

  desc 'all'
  task all: [
    'webpacker:yarn_install',
    'ci:setup',
    'ci:housekeep',
    'ci:migrate',
    'ci:minitest',
    'ci:brakeman:strict',
    'ci:bundle_audit',
    'ci:linguist',
    'ci:notes',
    'ci:stats',
    'ci:publish'
  ]
end
