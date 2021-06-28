module Report
  # Superclass for reports. This class should contain most of the functionality/boilerplate code
  # required to make creating new reports easier.
  #
  # Report creation/definition in a nutshell:
  # => Create a new subclass of Report::Base.
  # => Define a `relation` method, which will provide the raw data for the report.
  #    This should typically return an ActiveRecord::Relation, but any Enumerable could probably
  #    be made to work.
  # => Define the `columns` the report has.
  #    This should be an array of hashes, where each hash is a column definition, containing
  #    at minimum a `label` key/value pair (used as the column name/header in any rendered output),
  #    and an `accessor` key/value pair which specifies a method to which an enumerated object
  #    from `relation` will respond, which will be used for the column's output value. This may
  #    also be a `call`able object, which will receive the enumerated object as an argument.
  # => Update the `ability` file/class to grant report access to desired users/roles.
  class Base
    include ActiveModel::Model
    include ActiveModel::Attributes

    class_attribute :columns,       default: []
    class_attribute :download_only, default: false
    class_attribute :date_format,   default: '%d/%m/%Y'
    class_attribute :formatters,    default: {
      strftime: ->(value) { value && value.strftime(date_format) }
    }

    attribute :user_context

    delegate :title, :description, :column_labels, to: :class
    delegate :to_sql, to: :relation

    class << self
      def inherited(child_klass)
        super
        Report.register(child_klass)
      end

      def title
        human_attribute_name(:title, default: model_name.human)
      end

      def description
        human_attribute_name(:description, default: '').presence
      end

      def column_labels
        columns.pluck(:label)
      end

      # Bit of a bodge to make report _classes_ routable
      def to_param
        model_name.element
      end
    end

    # Underlying data for the report; should be defined by subclasses.
    def relation
      raise NotImplementedError
    end

    # Suggests a default filename for downloads of the report.
    def filename
      "#{title.parameterize(separator: '_')}_#{Time.zone.now.strftime('%Y%m%d')}"
    end

    def each(**options, &block)
      enumerable = options.key?(:paginate) ? relation.paginate(options[:paginate]) : relation

      yield_each(enumerable, &block)
    end

    def to_csv
      to_csv_enum.sum
    end

    # Allow downloads to be streamed back as they're generated:
    def to_csv_enum
      Enumerator.new do |enum|
        enum << CSV.generate_line(column_labels)

        each do |_entity, attributes|
          enum << CSV.generate_line(attributes)
        end
      end
    end

    private

    def yield_each(collection, &block)
      return enum_for(:yield_each, collection) unless block

      collection.map { |entity| block.call(entity, extract_columns(entity)) }
    end

    def extract_columns(entity)
      columns.map do |column|
        accessor = column.fetch(:accessor)
        format   = column.fetch(:format, [])

        format_with(*format) do
          accessor.is_a?(Proc) ? accessor.call(entity) : entity.try(accessor)
        end
      end
    end

    def format_with(*directives)
      value = yield

      return value if directives.empty?

      formatters.fetch_values(*directives).inject(value) do |memo, formatter|
        formatter.call(memo)
      end
    end
  end
end
