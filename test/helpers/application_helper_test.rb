require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  test 'async_content_tag' do
    project = projects(:dummy_project)
    url     = polymorphic_path([project, :comments])

    expected = "<div class='test' data-controller='async-loader' data-async-loader-url='#{url}'>" \
               '<strong>Loading</strong></div>'

    actual = async_content_tag(:div, url, class: 'test') do
      tag.strong('Loading')
    end

    assert_dom_equal expected, actual
  end
end
