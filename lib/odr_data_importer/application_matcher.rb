module OdrDataImporter
  # we'll need multiple times
  module ApplicationMatcher
    def find_existing_application(attrs)
      application_log = attrs['application_log'] || attrs['application log']

      existing_id = existing_application_log_for(application_log)
      return if existing_id.nil?

      applications = Project.of_type_application.where(application_log: existing_id)
      dup_msg = "More than one application found for #{existing_id}"
      # raise dup_msg if applications.count > 1
      print "WARNING - #{dup_msg}" if applications.count > 1

      applications.first
    end

    # ODR have appended '/another_id' to their ids
    def existing_application_log_for(odr_id)
      # the application_log exists as is
      return odr_id if odr_id.in? @existing_application_logs
      # the application_log prefix exists
      id = odr_id.split('/')
      print "WARNING - more id elements found for #{odr_id}\n" if id.count > 2

      id.first if id.first.in? @existing_application_logs

      # else no match
    end

    def build_application_log_lookup
      applications = read_excel_file(SafePath.new('tmp').join('Application data 20200728.xlsx'), 'Applications')
      applications_headers = applications.shift.map(&:downcase)

      applications.each_with_object([]) do |application, application_logs|
        applications_attrs = applications_headers.zip(application).to_h
        application_logs << applications_attrs['application_log']
      end
    end
  end
end
