module ApplicationHelper
  # The +opts+ should be in standard url_for form,
  # e.g. :controller => 'user', :action => 'show', :id => '12345'
  def cancel_submit(opts = {})
    # If an incomplete hash was supplied (e.g. missing id), just go back:
    url = opts.is_a?(Hash) && (opts.blank? || opts.values.any?(&:blank?)) ? :back : opts

    link_to("Don't save".html_safe, url, class: 'btn btn-default') + ' ' +
      submit_tag('Save', class: 'btn btn-primary', disable_with: 'Saving&hellip;'.html_safe)
  end

  def panel_heading_segments(left: nil, center: nil, right: nil)
    content_tag(:div, class: 'row') do
      safe_join(
        [
          content_tag(:div, left, class: 'col-md-3'),
          content_tag(:div, center, class: 'col-md-6 text-center'),
          content_tag(:div, class: 'col-md-3') { content_tag(:div, right, class: 'pull-right') }
        ]
      )
    end
  end

  def show_check_icon(boolean_value)
    if boolean_value then
      "<i class='fa-li fa fa-check-square'></i>"
    else
      "<i class='fa-li fa fa-square'></i>"
    end
  end

  def close_modal
    submit_tag 'Cancel', class: 'btn btn-default', 'data-dismiss' => 'modal'
  end

  def link_to_add_row(name, form, association, **args)
    new_object = form.object.send(association).klass.new
    id = new_object.object_id
    fields = form.fields_for(association, new_object, child_index: id) do |builder|
      render(args.fetch(:partial, association.to_s.singularize), form: builder)
    end
    link_to(name, '#', class: "add_fields " + args[:class], data: {id: id, fields: fields.gsub("\n", "")})
  end

  # TODO: dry up
  def link_to_add_address(name, form, association, **args)
    new_object = form.object.send(association).klass.new
    id = new_object.object_id
    fields = form.fields_for(association, new_object, child_index: id) do |builder|
      render('shared/address', form: builder)
    end
    link_to(name, '#', class: "add_fields " + args[:class], data: {id: id, fields: fields.gsub("\n", "") })
  end

  def async_content_tag(tag, path, options = {}, &block)
    defaults = {
      data: {
        controller: 'async-loader',
        'async-loader-url': path
      }
    }

    content_tag(tag, nil, defaults.deep_merge(options), &block)
  end
end
