# Parent class for all lookup models.
class ApplicationLookup < ActiveRecord::Base
  self.abstract_class = true

  class_attribute :value_column, default: :value, instance_reader: false, instance_writer: false

  scope :in_order, -> { order(Arel.sql("coalesce(#{value_column}, '')")) }

  class << self
    # This method exists as a proxy and can be overriden by subclasses.
    def valid_value?(value)
      # This is a performance hotspot.
      #
      # Use of #limit(1):
      #   Don't continue scanning after a match (may not factor in unique constraint).
      #
      # Not using #exists?:
      #   Would circumvent the query cache.
      where(primary_key => value).limit(1).count.positive?
    end

    def value_for(key)
      find_by(primary_key => key).try(value_column)
    end
  end

  def value_column
    send(self.class.value_column)
  end

  def to_listitem
    value_column
  end

  def to_select_option
    [to_listitem, id]
  end
end
