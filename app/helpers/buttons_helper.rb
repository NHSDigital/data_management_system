# Adds some helpers for drawing UI controls.
module ButtonsHelper
  # TODO: Move to ndr_ui?
  #       DRY up more of the buttons in helper methods
  def download_link(path, options = {})
    defaults   = { icon: 'cloud-download', title: 'Download', path: path }
    data_attrs = options.fetch(:data, {})
    data_attrs.merge!(
      confirm: 'This will download the original file onto your hard drive. Continue?'
    ) unless confirmation?(options)
    link_to_with_icon defaults.merge(options.merge(data: data_attrs))
  end

  # Lifted from ndtmsv2
  def tab_to(text, target, options = {})
    count = options.delete(:count)
    right = options.delete(:right)
    
    text = ERB::Util.h(text + ' ') + content_tag(:span, count, class: 'badge') if count

    classes = []
    classes << 'active'     if current_page?(target)
    classes << 'pull-right' if right

    content_tag(:li, class: safe_join(classes, ' ').presence) { link_to(text, target, options) }
  end

  def tab_to_partial(text, target, options = {})
    count = options.delete(:count)
    right = options.delete(:right)
    text = ERB::Util.h(text + ' ') + content_tag(:span, count, class: 'badge') if count

    classes = []
    classes << 'active'     if current_page?(target)
    classes << 'pull-right' if right

    content_tag(:li, class: safe_join(classes, ' ').presence) { link_to(text, target, options) }
  end

  private

  def confirmation?(options)
    options[:no_notice]
  end
end
