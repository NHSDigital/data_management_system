require 'test_helper'

class ProjectAttachmentTest < ActiveSupport::TestCase
  setup do
    @project_attachment = project_attachments(:one)
  end

  test 'should write a file upload into project_attachment.attachment_contents' do
    contents = 'MBilicious!'
    filename = 'mbis.txt'
    upload   = new_upload(filename, contents)

    pa = ProjectAttachment.new(upload: upload)

    assert_equal filename, pa.attachment_file_name
    assert_equal contents, pa.attachment_contents
    pa.attachment_content_type = 'text/plain'
    pa.attachable = Project.first
    assert pa.valid?
    pa.attachment_file_size = 6.megabytes
    refute pa.valid?
    pa.attachment_file_size = 1.megabyte
    assert pa.valid?
    pa.attachment_content_type = 'blah'
    refute pa.valid?
  end

  test 'should have a digest' do
    @project_attachment.assign_attributes(attachment_contents: nil, digest: nil)
    assert_nil @project_attachment.digest

    @project_attachment.attachment_contents = 'z' * 42
    assert_equal '099092b8a1373f87a10759d8d75afa1a', @project_attachment.digest
    assert_nil @project_attachment[:digest]

    @project_attachment.upload = new_upload('upload.txt', 'a' * 42)
    assert_equal 'af205d729450b663f48b11d839a1c8df', @project_attachment.digest
    assert_not_nil @project_attachment[:digest]
  end

  test 'should ensure digest is set before validation' do
    @project_attachment.assign_attributes(attachment_contents: 'a' * 42, digest: nil)
    @project_attachment.valid?

    assert_not_nil @project_attachment[:digest]
  end

  test 'digests should be unique within the context of a project' do
    this_project  = projects(:new_project)
    other_project = projects(:one)
    first_upload  = new_upload('first.txt', 'a' * 42)
    second_upload = new_upload('second.txt', 'a' * 42)

    attachment        = this_project.project_attachments.build
    attachment.upload = first_upload
    assert attachment.save

    attachment        = other_project.project_attachments.build
    attachment.upload = first_upload
    assert attachment.save

    expected_error    = { error: :taken, value: 'af205d729450b663f48b11d839a1c8df' }
    attachment        = this_project.project_attachments.build
    attachment.upload = second_upload
    refute attachment.save
    assert_includes attachment.errors.details[:digest], expected_error
  end

  private

  def new_upload(filename, contents)
    ActionDispatch::Http::UploadedFile.new(
      tempfile: StringIO.new(contents),
      filename: filename,
      type:     'text/plain'
    )
  end
end
