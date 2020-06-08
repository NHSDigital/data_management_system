# Adds `belongs_to_lookup` for managing lookup associations
module BelongsToLookup
  extend ActiveSupport::Concern

  class_methods do
    def belongs_to_lookup(attribute, lookup_class, options = {})
      defaults = { class_name: lookup_class.name, foreign_key: attribute, optional: true }
      scope    = options.delete(:scope)

      belongs_to :"#{attribute}_lookup", scope, defaults.merge!(options)

      define_singleton_method("#{attribute}_lookup_class") { lookup_class }
      delegate "#{attribute}_lookup_class", to: :class

      define_method("#{attribute}_lookup_value") { send("#{attribute}_lookup").try(:value_column) }

      validator_method = define_method("ensure_#{attribute}_lookup_valid") do
        ensure_sane_typecasting(attribute)
        ensure_lookup_valid(attribute)
      end

      validate validator_method
    end
  end

  included do
    after_validation :move_lookup_errors
    before_save      :nullify_blank_lookups
  end

  private

  def move_lookup_errors
    source_names = self.class.reflect_on_all_associations.map(&:name).grep(/_lookup$/)

    source_names.each do |source_name|
      target_name = source_name.to_s.chomp('_lookup')
      errors[source_name].each { |message| errors.add(target_name, message) }
      errors.delete(source_name)
    end
  end

  # Fields can be set to "" by the :include_blank option, however this is not
  # equivalent to NULL in Postgres, so causes foreign key validation errors.
  def nullify_blank_lookups
    source_names = self.class.reflect_on_all_associations.map(&:name).grep(/_lookup$/)

    source_names.each do |source_name|
      attribute = source_name.to_s.chomp('_lookup')
      send("#{attribute}=", nil) if send(attribute).blank?
    end
  end

  def ensure_sane_typecasting(attribute)
    attribute = attribute.to_s

    # Only check integer columns:
    return unless :integer == self.class.columns_hash[attribute].try(:type)

    # If the cast value completes the roundtrip back to the before value, we're ok:
    return if attributes_before_type_cast[attribute].to_s == send(attribute).to_s

    errors.add(attribute, :lookup)
  end

  def ensure_lookup_valid(attribute)
    code  = send(attribute)
    value = code ? send("#{attribute}_lookup") : nil

    return if code.blank? || value

    errors.add(attribute, :lookup)
  end
end
