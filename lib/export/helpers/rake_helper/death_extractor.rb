module Export
  module Helpers
    # Helper methods, for inclusion into rake tasks
    module RakeHelper
      # Helpers to extract death records
      module DeathExtractor
        # Interactively pick a weekly batch of death data
        # If optional week parameter is supplied (in YYYY-MM-DD format), then this runs in
        # batch mode, and returns the latest data for that week, or raises an exception if no
        # batch for that month is available.
        def self.pick_mbis_weekly_death_batch(desc, fname_patterns, weeks_ago: 4,
                                                                    week: nil)
          if week && !/\A[0-9]{4}-[0-9]{2}-[0-9]{2}\z/.match?(week)
            raise(ArgumentError, "Invalid week #{week}, expected YYYY-MM-DD")
          end

          date0 = if week
                    Date.strptime(week, '%Y-%m-%d')
                  else
                    Date.current - weeks_ago * 7
                  end
          weekly_death_re = /MBIS(WEEKLY_Deaths_D|_20)([0-9]{6}).txt/ # TODO: Refactor
          batch_scope = EBatch.imported.where(e_type: 'PSDEATH')

          dated_batches = batch_scope.all.collect do |eb|
            next unless weekly_death_re =~ eb.original_filename

            date = Date.strptime(Regexp.last_match(2), '%y%m%d')
            next if date < date0

            [date, fname_patterns.collect { |s| date.strftime(s) }, eb]
          end.compact.sort
          if week
            date, fnames, eb = dated_batches.reverse.find do |date, _, _|
              date.strftime('%Y-%m-%d') == week
            end
            raise "No batch found for week #{week}" unless date

            puts "Extracting week #{week} with e_batchid #{eb.id}"
          else
            puts "e_batchid: original MBIS filename -> #{desc} files"
            dated_batches.each do |_date, fnames, eb|
              puts format('%-9d: %s -> %s', eb.id, Pathname.new(eb.original_filename).basename,
                          fnames[0..1].collect { |s| File.basename(s) }.join(', '))
            end
            print 'Choose e_batchid to export, or enter "older" to show older batches: '
            answer = STDIN.readline.chomp
            if answer == 'older'
              return pick_mbis_weekly_death_batch(desc, fname_patterns,
                                                  weeks_ago: weeks_ago + 4)
            end

            e_batchid = answer.to_i
            date, fnames, eb = dated_batches.find { |_, _, eb2| eb2.id == e_batchid }
          end
          fnames&.each do |fname|
            raise "Not overwriting existing #{fname}" if File.exist?(SafePath.new('mbis_data').
                                                                      join(fname))
          end
          [date, fnames, eb]
        end

        def self.extract_mbis_weekly_death_file(e_batch, fname, klass, filter = nil)
          puts "Extracting #{fname}..."
          system('rake', e_batch.e_type == 'PSDEATH' ? 'export:death' : 'export:birth',
                 "fname=#{fname.sub(%r{\Aextracts/}, '')}", # Remove extracts/ prefix for rake task
                 "original_filename=#{e_batch.original_filename}",
                 "klass=#{klass}", "filter=#{filter}")
          full_fname = SafePath.new('mbis_data').join(fname)
          File.exist?(full_fname)
        end

        # Which batch filenames should be included in this month's extract?
        # Returns a pair: a pattern for matching all the batches in the month, and a pattern
        # for the final batch to include in the current month's extract
        def self.monthly_batch_patterns(date)
          this_month_yymm = date.strftime('%y%m')
          last_month_yymm = (date - 1.month).strftime('%y%m')
          if date < Date.new(2019, 8, 1)
            # From the 3rd batch of last month, to the second batch of this month
            # Final batch will be received 8th-14th of the month
            [Regexp.new('/MBIS(WEEKLY_Deaths_D|_20)' \
                        "(#{last_month_yymm}(1[5-9]|[23][0-9])" \
                        "|#{this_month_yymm}(0[0-9]|1[0-4])).txt"),
             /(0[89]|1[0-4]).txt/]
          elsif date < Date.new(2019, 9, 1)
            # From the 3rd batch of last month, to the third batch of this month
            # Final batch will be received 15th-21st of the month
            [Regexp.new('/MBIS(WEEKLY_Deaths_D|_20)' \
                        "(#{last_month_yymm}(1[5-9]|[23][0-9])" \
                        "|#{this_month_yymm}([01][0-9]|2[0-1])).txt"),
             /(1[5-9]|2[0-1]).txt/]
          elsif date < Date.new(2019, 10, 1)
            # From the 4th batch of last month, to the fourth batch of this month
            # Final batch will be received 22nd-28th of the month
            [Regexp.new('/MBIS(WEEKLY_Deaths_D|_20)' \
                        "(#{last_month_yymm}(2[2-9]|3[0-1])" \
                        "|#{this_month_yymm}([01][0-9]|2[0-8])).txt"),
             /(2[2-8]).txt/]
          else
            # From the 5th batch of last month, to the fourth batch of this month
            # Final batch will be received 22nd-28th of the month
            [Regexp.new('/MBIS(WEEKLY_Deaths_D|_20)' \
                        "(#{last_month_yymm}(29|3[0-1])" \
                        "|#{this_month_yymm}([01][0-9]|2[0-8])).txt"),
             /(2[2-8]).txt/]
          end
        end

        # Interactively pick month's data, after the final MBIS weekly batch of each month
        # If optional month parameter is supplied (in YYYY-MM format), then this runs in
        # batch mode, and returns the latest data for that month, or raises an exception if no
        # batch for that month is available.
        def self.pick_mbis_monthly_death_batches(desc, fname_patterns, months_ago: 2,
                                                                       month: nil)
          month = ENV['month']
          if month
            year0, month0 = /^([0-9]{4})-([0-9]{2})$/.match(month)[1..2].collect(&:to_i)
            months_ago = (Time.current.year - year0) * 12 + (Time.current.month - month0)
          end
          weekly_death_re = /MBIS(WEEKLY_Deaths_D|_20)([0-9]{6}).txt/ # TODO: Refactor
          batch_scope = EBatch.imported.where(e_type: 'PSDEATH')
          # Second batches would usually be those received 8th-14th of each month
          # and would be those from the previous month with a day-of-month of 15-31
          # for the previous month and 1-14 for the current month.
          monthly_batches = (0..months_ago).collect do |n|
            pattern, final_batch_re = monthly_batch_patterns(n.month.ago)
            batches = batch_scope.all.select { |eb| eb.original_filename =~ pattern }
            # Ignore unless this contains a record from the final week of the month
            # (second week (8th to 14th) up to 2019-07-31, or from 2019-08-01 onwards,
            # a record from the third week (15th to 21st) of the month.
            next unless batches.any? { |eb| eb.original_filename =~ final_batch_re }

            batches.sort_by(&:e_batchid) # latest last
          end.compact
          dated_batches = monthly_batches.collect do |batches|
            next if batches.empty?

            eb = batches.last
            next unless weekly_death_re =~ eb.original_filename

            date = Date.strptime(Regexp.last_match(2), '%y%m%d')
            [date, fname_patterns.collect { |s| date.strftime(s) }, eb, batches]
          end.compact.sort
          if month
            date, fnames, _eb, batches = dated_batches.reverse.find do |date, _, _, _|
              date.strftime('%Y-%m') == month
            end
            raise "No batch found for month #{month}" unless date

            puts "Extracting month #{month} with e_batchids #{batches.collect(&:id)}"
          else
            puts "e_batchid: original MBIS filename -> #{desc} files"
            dated_batches.each do |_date, fnames, eb, batches|
              # next unless date >= 1.month.ago
              puts format('%-9d: %s -> %s', eb.id, Pathname.new(eb.original_filename).basename,
                          fnames[0..1].join(', '))
              (batches - [eb]).each do |eb2|
                puts "           (+ #{Pathname.new(eb2.original_filename).basename})"
              end
            end
            print 'Choose e_batchid to export, or enter "older" to show older batches: '
            answer = STDIN.readline.chomp
            if answer == 'older'
              return pick_mbis_monthly_death_batches(desc, fname_patterns,
                                                     months_ago: months_ago + 3)
            end

            e_batchid = answer.to_i
            date, fnames, _eb, batches = dated_batches.find { |_, _, eb2, _| eb2.id == e_batchid }
          end
          fnames&.each do |fname|
            raise "Not overwriting existing #{fname}" if File.exist?(SafePath.new('mbis_data').
                                                                      join(fname))
          end
          [date, fnames, batches]
        end
      end
    end
  end
end
