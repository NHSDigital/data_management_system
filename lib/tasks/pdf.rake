namespace :pdf do
  desc 'PoC PDF AcroForm reader using the pdf-reader gem'
  task form_reader: :environment do
    # Usage: bundle exec rake pdf:form_reader FILENAME="..."
    require 'pdf-reader'

    PDF::Reader.module_eval do
      def acroform
        @objects.deref(root[:AcroForm])
      end

      def each_acroform_field
        return enum_for(:each_acroform_field) unless block_given?

        acroform[:Fields].each do |field_ref, _hash|
          field = @objects[field_ref]
          unless field[:Subtype] == :Widget || field.key?(:Kids)
            raise "Widgets or Radio boxes expected, found a #{field[:Subtype].inspect}"
          end

          yield(field[:T], field[:V], field)
        end
      end
    end

    filename = Rails.root.join(ENV['FILENAME'])
    reader = PDF::Reader.new(filename)

    hash = {}
    reader.each_acroform_field do |field_name, value|
      raise "Non-unique column name #{field_name}" if hash.key?(field_name)

      hash[field_name] = value
    end
    puts hash.to_yaml
  end
end
