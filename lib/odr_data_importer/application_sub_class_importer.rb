module OdrDataImporter
  # start point for importing amendments, contracts, dpias, releases
  module ApplicationSubClassImporter
    def import_application_sub_class(create_sub_class)
      header = @excel_file.shift.map(&:downcase)
      log_to_process_count(@excel_file.count)

      @excel_file.map { |a| attrs = header.zip(a).to_h; attrs['application_log'] }.uniq.count
      @existing_application_logs = build_application_log_lookup

      no_parent_applications = []
      counter = 0

      Project.transaction do
        @excel_file.each do |sub_class|
          attrs = header.zip(sub_class).to_h

          application = find_existing_application(attrs)
          if application.nil?
            no_parent_applications << attrs['application_log'] 
          else
            send(create_sub_class, application, attrs)
            print "#{counter += 1}\r"
          end
        end
        errors_to_file(no_parent_applications, "#{create_sub_class}_no_parent_applications")
        print "#{counter} #{create_sub_class} created\n"
      end
    end
  end
end
