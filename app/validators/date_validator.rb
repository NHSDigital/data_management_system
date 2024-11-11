# This validator give you the ability to validate dates.
#
# validates :attribute_name, date: { no_future: true }
class DateValidator < ActiveModel::EachValidator
  COMPARATOR = {
    not_after: :>,
    not_before: :<
  }.freeze

  def validate_each(record, attribute, value)
    return if value.blank?
    value = evaluate_options_value(record) if options.key?(:value)

    validate_no_future(record, attribute, value)

    compare(:not_after, record, attribute, value)
    compare(:not_before, record, attribute, value)

    return if options.except(:not_after, :not_before, :message, :no_future, :value, :if, :unless).empty?
    fail "TODO: DateValidator attribute: #{attribute.inspect} #{options.inspect}"
  end

  private

  def validate_no_future(record, attribute, value)
    return unless options[:no_future] && value > Time.zone.today

    record.errors.add(attribute, :no_future, **options)
  end

  def evaluate_options_value(record)
    case options[:value]
    when Proc
      options[:value].call(record)
    else
      fail options[:value].class.to_s
    end
  end

  def compare(mode, record, attribute, value)
    raise ArgumentError unless COMPARATOR.key?(mode)
    return unless options.key?(mode)

    comparison = comparative_value(options[mode], record)
    return unless comparison && value.send(COMPARATOR[mode], comparison)

    human_name = comparative_name(options[mode], record)
    record.errors.add(attribute, mode, **options.except().merge!(comparison: human_name))
  end

  def comparative_value(comparative_option, record)
    case comparative_option
    when Date
      comparative_option
    when Symbol
      record.send(comparative_option)
    when Proc
      comparative_option.call(record)
    else
      fail comparative_option.class.to_s
    end
  end

  def comparative_name(comparative_option, record)
    case comparative_option
    when Date, Proc
      comparative_value(comparative_option, record).try(:to_fs, :ui)
    when Symbol
      record.class.human_attribute_name(comparative_option)
    else
      fail comparative_option.class.to_s
    end
  end
end
