require 'test_helper'

class ProjectDataEndUserTest < ActiveSupport::TestCase
  test 'Upload from file creates end users' do
    project  = projects(:one)
    contents = "first_name,last_name,email,ts_cs_accepted\nfirst,last,email@phe.gov.uk,1\n"
    filename = 'mbis.csv'
    upload   = ActionDispatch::Http::UploadedFile.new(
      tempfile: StringIO.new(contents),
      filename: filename
    )

    attachment = project.project_attachments.build(
      upload: upload,
      attachment_content_type: 'text/csv'
    )

    attachment.stubs(valid?: true)

    assert_no_difference -> { project.project_data_end_users.count } do
      attachment.name = 'Not an End Users File'
      attachment.import_end_users
    end

    assert_difference -> { project.project_data_end_users.count } do
      attachment.name = 'Data End Users'
      attachment.import_end_users
    end
  end
end
