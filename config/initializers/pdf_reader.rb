require 'pdf-reader'

module PDF
  # PoC PDF AcroForm reader using the pdf-reader gem
  module AcroForm
    def acroform
      @objects.deref(root[:AcroForm])
    end

    def acroform_data
      each_acroform_field.inject({}) do |data, (field_name, field_value)|
        raise "Non-unique column name #{field_name}" if data.key?(field_name)

        data.update(field_name => field_value)
      end
    end

    def each_acroform_field
      return enum_for(:each_acroform_field) unless block_given?

      acroform[:Fields].each do |field_ref|
        field = @objects[field_ref]

        unless field[:Subtype] == :Widget || field.key?(:Kids)
          raise "Widgets or Radio boxes expected, found a #{field[:Subtype].inspect}"
        end

        yield(field[:T], @objects.deref(field[:V]))
      end
    end
  end

  # High and low level utility methods for extracting embedded files.
  # TODO: From the docs: "Embedded file streams may be associated with the document as a
  # whole through the EmbeddedFiles entry in the PDF document's name dictionary"
  module Attachments
    def files
      attachments.map do |specification, stream|
        hash   = stream.hash
        params = hash[:Params]
        parser = proc { |date_str| date_str ? Time.zone.parse(date_str.slice(2..-5)) : nil }
        digest = params.key?(:CheckSum) ? Digest.hexencode(params[:CheckSum]) : nil

        EmbeddedFile.new specification[:F],
                         params[:Size],
                         parser.call(params[:CreationDate]),
                         parser.call(params[:ModDate]),
                         hash[:Subtype],
                         digest,
                         stream.unfiltered_data
      end
    end

    def attachments
      file_annotations    = annotations.find_all { |annot| annot[:Subtype] == :FileAttachment }
      file_specifications = file_annotations.map { |annot| objects.deref(annot[:FS]) }

      file_specifications.inject({}) do |hash, file_specification|
        file_stream = objects.deref(file_specification[:EF][:F])
        hash.update(file_specification => file_stream)
      end
    end

    private

    def annotations
      pages.flat_map do |page|
        page_annots = page.objects.deref(page.attributes[:Annots])
        page_annots.map { |ref| page.objects.deref(ref) }
      end
    end

    EmbeddedFile = Struct.new(:filename, :size, :created, :modified, :mime_type, :md5, :data)
  end
end
PDF::Reader.include(PDF::AcroForm)
PDF::Reader.include(PDF::Attachments)
