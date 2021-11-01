module Export
  module Helpers
    # Helper methods, for inclusion into rake tasks
    module RakeHelper
      # Helpers to extract weekly / monthly / regular periodic death records
      class RegularExtracts
        COLUMNS = %w[e_type klass project_name team_name frequency filter].freeze

        def initialize(config_fname, e_types, logger: Rails.logger)
          @config = CSV.read(config_fname, headers: true)
          unless @config.headers == COLUMNS
            raise "Error: invalid headers in config file #{config_fname}. Got headers " \
                  "#{config.headers.join(',').inspect}, expected #{COLUMNS.join(',').inspect}"
          end
          @e_types = e_types
          @logger = logger
        end

        def export_all(start_date, end_date)
          @exported = []
          @errors = [] # Defer errors until we have at least run as many extracts as we can
          @config.each.with_index do |row, i|
            e_type = row['e_type']
            next unless @e_types.include?(e_type)

            begin
              klass = row['klass']&.constantize
            rescue NameError
              @errors << "Unknown class #{row['klass'].inspect} on row #{i + 1}"
              next
            end
            project_name = row['project_name']
            team_name = row['team_name']
            frequency = row['frequency']
            filter = row['filter']
            unless %w[PSBIRTH PSDEATH].include?(e_type)
              @errors << "Unknown e_type #{e_type.inspect} on row #{i + 1}"
              next
            end
            unless %w[weekly monthly].include?(frequency)
              @errors << "Unknown frequency #{frequency.inspect} on row #{i + 1}"
              next
            end
            begin
              encryptor = Export::Helpers::RakeHelper::EncryptOutput
              encryptor.find_project_data_password(project_name, team_name)
            rescue ArgumentError => e
              @errors << "Unknown project_name / team_name or missing passwords on row #{i + 1}: " \
                        "#{e}"
              next
            end
            run_extract(e_type, klass, project_name, team_name, frequency, filter,
                        start_date, end_date)
          end
          unless @exported.empty?
            @logger.warn 'Summary of successful exports:'
            @exported.each { |fn| @logger.warn "- #{fn}" }
          end
          return @exported.size if @errors.empty?

          @logger.warn 'Summary of errors:'
          @errors.each { |error| @logger.warn "- #{error}" }
          @logger.warn "ERROR: #{@errors.count} export failures, #{@exported.size} files " \
                       'successfully exported'
          raise 'ERROR: export failures'
        end

        def run_extract(e_type, klass, project_name, team_name, frequency, filter,
                        start_date, end_date)
          extractor = case e_type
                      when 'PSDEATH' then Export::Helpers::RakeHelper::DeathExtractor
                      else
                        @errors << "Unsupported e_type #{e_type}"
                        return
                      end
          unless klass.respond_to?(:fname_patterns)
            @errors << "class #{klass} does not define fname_patterns"
            return
          end

          case frequency
          when 'weekly'
            (start_date..end_date).each do |day|
              # Try all dates, although in practice we'll only get the Monday files
              day_iso = day.strftime('%Y-%m-%d')
              fname_patterns = [klass.fname_patterns(filter, :weekly)[2]] # only the .zip file
              fname_team     = team_name.parameterize(separator: '_')
              fname_project  = project_name.parameterize(separator: '_')
              extract_path   = if klass == Export::CancerDeathWeekly && filter == 'cd'
                                 'extracts/CD Weekly'
                               elsif klass == Export::PandemicFluWeekly
                                 'extracts/Pandemic Flu Weekly Extract'
                               elsif klass == Export::CdscWeekly
                                 'extracts/CDSC Weekly'
                               else
                                 "extracts/#{fname_team}/#{fname_project}"
                               end

              fname_patterns.map! do |fname_pattern|
                "#{extract_path}/%Y-%m-%d/#{fname_pattern}"
              end
              begin
                _date, fnames, _ebatch = extractor.pick_mbis_weekly_death_batch(project_name,
                                                                                fname_patterns,
                                                                                week: day_iso,
                                                                                logger: nil)
              rescue RuntimeError => e
                unless e.to_s.starts_with?('Not overwriting existing ') ||
                       e.to_s.starts_with?('No batch found for week ')
                  @errors << "Extract failed in pick_mbis_weeklyly_death_batch: #{e}"
                end
                next
              end
              fname = fnames.first
              if klass == Export::CancerDeathWeekly && filter == 'cd'
                system('rake', 'export:cd', "week=#{day_iso}")
              elsif klass == Export::PandemicFluWeekly
                system('rake', 'export:flu', "week=#{day_iso}")
              elsif klass == Export::CdscWeekly
                system('rake', 'export:cdsc', "week=#{day_iso}")
              else
                system('rake', e_type == 'PSDEATH' ? 'export:weekly:death' : 'export:weekly:birth',
                       "project_name=#{project_name}",
                       "team_name=#{team_name}",
                       "klass=#{klass}", "filter=#{filter}", "week=#{day_iso}",
                       "extract_path=#{extract_path}")
              end
              full_fname = SafePath.new('mbis_data').join(fname)
              unless File.exist?(full_fname)
                @errors << "Extract failed: no output file produced, expected #{fname.inspect}"
                next
              end
              @exported << fname
            end
          when 'monthly'
            # Check whether filename defined in export_monthly.rake already exists
            months = (start_date..end_date).collect { |date| date.strftime('%Y-%m') }.uniq
            months.each do |month|
              fname_patterns = [klass.fname_patterns(filter, :monthly)[2]] # only the .zip file
              fname_team     = team_name.parameterize(separator: '_')
              fname_project  = project_name.parameterize(separator: '_')
              extract_path   = if klass == Export::AidsDeathsMonthly
                                 'extracts/HIVAIDS Monthly Extract'
                               elsif klass == Export::KitDeathsFile
                                 'extracts/KIT Annual Extracts/KITDEATHS'
                               elsif klass == Export::NonCommunicableDiseaseMonthly
                                 'extracts/NCD Mortality Surveillance'
                               else
                                 "extracts/#{fname_team}/#{fname_project}"
                               end

              fname_patterns.map! do |fname_pattern|
                "#{extract_path}/%Y-%m-%d/#{fname_pattern}"
              end
              begin
                _date, fnames, _batches = extractor.pick_mbis_monthly_death_batches(project_name,
                                                                                    fname_patterns,
                                                                                    month: month,
                                                                                    logger: nil)
              rescue RuntimeError => e
                unless e.to_s.starts_with?('Not overwriting existing ') ||
                       e.to_s.starts_with?('No batch found for month ')
                  @errors << "Extract failed in pick_mbis_monthly_death_batches: #{e}"
                end
                # @logger.debug "Skipping: #{e} for month=#{month}"
                next
              end
              fname = fnames.first
              if klass == Export::AidsDeathsMonthly
                system('rake', 'export:aids', "month=#{month}")
              elsif klass == Export::KitDeathsFile
                system('rake', 'export:kitdeaths_monthly', "month=#{month}")
              elsif klass == Export::NonCommunicableDiseaseMonthly
                system('rake', 'export:ncd_monthly', "month=#{month}")
              else
                system('rake',
                       e_type == 'PSDEATH' ? 'export:monthly:death' : 'export:monthly:birth',
                       "project_name=#{project_name}",
                       "team_name=#{team_name}",
                       "klass=#{klass}", "filter=#{filter}", "month=#{month}",
                       "extract_path=#{extract_path}")
              end
              full_fname = SafePath.new('mbis_data').join(fname)
              unless File.exist?(full_fname)
                @errors << "Extract failed: no output file produced, expected #{fname.inspect}"
                next
              end
              @exported << fname
            end
          else raise 'Unknown frequency'
          end
        end
      end
    end
  end
end
