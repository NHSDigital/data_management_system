module Bootstrap
  module Extensions
    def lookup_select(method, disabled: false, data: nil)
      lookup_method = "#{method}_lookup"
      raise "Unknown association: #{lookup_method}" unless object.respond_to?(lookup_method)

      association = object.class.reflect_on_association(lookup_method)
      klass       = association.klass
      scope       = association.scope

      collection = klass.none if readonly?
      collection ||= scope ? scope.call : klass.all

      current_value  = object.send(method)
      select_options = collection.map(&:to_select_option)

      options = {
        include_blank: true,
        readonly_value: object.send(lookup_method).try(:value_column)
      }

      html = { disabled: disabled }
      html.merge!(data: data) if data

      select(method, @template.options_for_select(select_options, current_value), options, html)
    end

    def lookup_select_group(method, **options)
      control_group(method, options.delete(:text)) do
        lookup_select(method, **options)
      end
    end
  end
end

ActiveSupport.on_load :bootstrap_builder do
  include Bootstrap::Extensions
end
