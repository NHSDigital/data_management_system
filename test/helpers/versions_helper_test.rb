require 'test_helper'

# Test helpers exposed in VersionsHelper.
class VersionsHelperTest < ActionView::TestCase
  test 'version_path' do
    project = projects(:one)
    version = PaperTrail::Version.new item: project, event: 'test', id: 1
    expected = "/projects/#{project.id}/versions/1"

    assert_equal expected, version_path(version)
  end

  test 'versions_path' do
    project = projects(:one)
    expected = "/projects/#{project.id}/versions"

    assert_equal expected, versions_path(project)
  end

  test 'version_siblings_tag' do
    project = projects(:one)
    2.times { PaperTrail::Version.create(item: project, event: 'test') }

    v1, v2 = project.versions

    expected = '<div class="btn-group">' +
               %(<a href="#{version_path(v1)}" disabled="disabled" class="btn btn-default">) +
               'previous</a>' +
               %(<a href="#{version_path(v2)}" class="btn btn-default">) +
               'next</a></div>'

    assert_dom_equal expected, version_siblings_tag(v1)
  end

  test 'versions_link' do
    project  = projects(:one)
    expected = %(<a class="btn btn-default" href="#{versions_path(project)}">) +
               '<span class="glyphicon glyphicon-time"></span> Audit</a>'

    assert_dom_equal expected, versions_link(project)
  end
end
