require 'test_helper'

# Test bootstrap form builder
class BootstrapBuilderTest < ActionView::TestCase
  tests ActionView::Helpers::FormHelper
  include NdrUi::BootstrapHelper

  def setup
    @release = Release.new(project: projects(:dummy_project))
  end

  test 'lookup_select_group with title' do
    @output_buffer =
      bootstrap_form_for @release, url: '#' do |form|
        form.lookup_select_group :vat_reg, text: 'RAWR'
      end

    assert_select 'div.form-group' do
      assert_select 'label.control-label', text: 'RAWR'
    end
  end

  test 'lookup_select_group with a scoped association' do
    @output_buffer =
      bootstrap_form_for @release, url: '#' do |form|
        form.lookup_select_group :income_received
      end

    assert_select 'option', text: ''
    assert_select 'option', text: 'Yes'
    assert_select 'option', text: 'No'
    assert_select 'option', text: 'Not Applicable', count: 0
  end
end
