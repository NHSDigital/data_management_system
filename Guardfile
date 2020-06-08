# A sample Guardfile
# More info at https://github.com/guard/guard#readme

# This group allows to skip running rubocop when tests fail.
group :red_green_refactor, halt_on_fail: true do
  guard :test, all_on_start: false, spring: true, all_after_pass: false do
    watch(%r{^test/.+_test\.rb$})
    watch('test/test_helper.rb') { 'test' }

    # Non-rails
    watch(%r{^lib/(.+)\.rb$}) { |m| "test/#{m[1]}_test.rb" }

    # Rails 4
    # watch(%r{^app/(.+)\.rb})                               { |m| "test/#{m[1]}_test.rb" }
    # watch(%r{^app/controllers/application_controller\.rb}) { 'test/controllers' }
    # watch(%r{^app/controllers/(.+)_controller\.rb})        { |m| "test/integration/#{m[1]}_test.rb" }
    # watch(%r{^app/views/(.+)_mailer/.+})                   { |m| "test/mailers/#{m[1]}_mailer_test.rb" }
    # watch(%r{^lib/(.+)\.rb})                               { |m| "test/lib/#{m[1]}_test.rb" }

    # Rails < 4
    watch(%r{^app/lookup_models/(.+)\.rb$})            { |m| "test/unit/lookup_models/#{m[1]}_test.rb" }
    watch(%r{^app/measurement_models/(.+)\.rb$})       { |m| "test/unit/measurement_models/#{m[1]}_test.rb" }
    watch(%r{^app/models/(.+)\.rb$})                   { |m| "test/unit/#{m[1]}_test.rb" }
    watch(%r{^app/source_models/(.+)\.rb$})            { |m| "test/unit/source_models/#{m[1]}_test.rb" }
    watch(%r{^app/controllers/(.+)\.rb$})              { |m| "test/functional/#{m[1]}_test.rb" }
    watch(%r{^app/views/(.+)/.+\.erb$})                { |m| "test/functional/#{m[1]}_controller_test.rb" }
    watch(%r{^app/views/.+$})                          { 'test/integration' }
    watch('app/controllers/application_controller.rb') { ['test/functional', 'test/integration'] }
  end

  # automatically check Ruby code style with Rubocop when files are modified
  guard :shell do
    watch(/.+\.(rb|rake)$/) do |m|
      unless system("bundle exec rake rubocop:diff #{m[0]}")
        Notifier.notify "#{File.basename(m[0])} inspected, offenses detected",
                        title: 'RuboCop results (partial)', image: :failed
      end
      nil
    end
  end
end

guard 'livereload' do
  extensions = {
    css: :css,
    scss: :css,
    sass: :css,
    js: :js,
    coffee: :js,
    html: :html,
    png: :png,
    gif: :gif,
    jpg: :jpg,
    jpeg: :jpeg,
    # less: :less, # uncomment if you want LESS stylesheets done in browser
  }

  rails_view_exts = %w(erb haml slim)

  # file types LiveReload may optimize refresh for
  compiled_exts = extensions.values.uniq
  watch(%r{public/.+\.(#{compiled_exts * '|'})})

  extensions.each do |ext, type|
    watch(%r{
          (?:app|vendor)
          (?:/assets/\w+/(?<path>[^.]+) # path+base without extension
           (?<ext>\.#{ext})) # matching extension (must be first encountered)
          (?:\.\w+|$) # other extensions
          }x) do |m|
      path = m[1]
      "/assets/#{path}.#{type}"
    end
  end

  # file needing a full reload of the page anyway
  watch(%r{app/views/.+\.(#{rails_view_exts * '|'})$})
  watch(%r{app/helpers/.+\.rb})
  watch(%r{config/locales/.+\.yml})
end
