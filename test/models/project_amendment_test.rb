require 'test_helper'

class ProjectAmendmentTest < ActiveSupport::TestCase
  test 'should belong to a project' do
    project   = projects(:one)
    amendment = project.project_amendments.build

    assert_equal project, amendment.project
    assert_includes project.project_amendments, amendment
  end

  test 'should be invalid without a project' do
    amendment = ProjectAmendment.new
    amendment.valid?

    assert_includes amendment.errors.details[:project], error: :blank

    amendment.project = projects(:one)
    amendment.valid?

    refute_includes amendment.errors.details[:project], error: :blank
  end

  test 'should be associated with a project state' do
    project   = projects(:one)
    amendment = create_amendment(project)

    assert_equal project.current_project_state, amendment.project_state
  end

  test 'should be invalid without an associated project_state' do
    amendment = ProjectAmendment.new
    amendment.valid?

    assert_includes amendment.errors.details[:project_state], error: :blank
  end

  test 'should be invalid without a requested date' do
    project   = projects(:one)
    amendment = project.project_amendments.build

    amendment.valid?

    assert_includes amendment.errors.details[:requested_at], error: :blank

    amendment.requested_at = Time.zone.today
    amendment.valid?

    refute_includes amendment.errors.details[:requested_at], error: :blank
  end

  test 'should not allow requested dates in the future' do
    project   = projects(:one)
    amendment = project.project_amendments.build(requested_at: Time.zone.tomorrow)

    amendment.valid?

    assert_includes amendment.errors.details[:requested_at], error: :no_future, no_future: true
  end

  test 'should not allow amendment_approved_date in the future' do
    project   = projects(:one)
    amendment = project.project_amendments.build(amendment_approved_date: Time.zone.tomorrow)

    amendment.valid?

    assert_includes amendment.errors.details[:amendment_approved_date], error: :no_future,
                                                                        no_future: true
  end

  test 'should be valid without an attachment' do
    project   = projects(:one)
    amendment = project.project_amendments.build(requested_at: Time.zone.today)

    amendment.valid?

    refute_includes amendment.errors.details[:attachment], error: :blank
  end

  test 'should validate attachment when present' do
    project    = projects(:one)
    amendment  = project.project_amendments.build(requested_at: Time.zone.today)

    amendment.build_attachment(
      attachment_content_type: 'invalid/mime',
      attachment_file_size: 6.megabytes
    )

    amendment.valid?

    assert_includes amendment.errors.details[:digest], error: :blank

    expected = { error: :inclusion, value: 'invalid/mime' }
    assert_includes amendment.errors.details[:attachment_content_type], expected

    expected = { error: :less_than_or_equal_to, value: 6.megabytes, count: 5.megabytes }
    assert_includes amendment.errors.details[:attachment_file_size], expected
  end

  test 'should require attachment to be valid PDF' do
    project   = projects(:one)
    amendment = project.project_amendments.build(requested_at: Time.zone.today)

    amendment.valid?
    refute_includes amendment.errors.details[:attachment], error: :bad_pdf

    fixture = file_fixture('fivemb.txt')
    upload  = ActionDispatch::Http::UploadedFile.new(
      tempfile: File.new(fixture, 'rb'),
      filename: fixture.basename.to_s,
      type:     'text/plain'
    )

    amendment.upload = upload
    amendment.valid?
    assert_includes amendment.errors.details[:attachment], error: :bad_pdf

    fixture = file_fixture('odr_amendment_request_form-1.0.pdf')
    upload  = ActionDispatch::Http::UploadedFile.new(
      tempfile: File.new(fixture, 'rb'),
      filename: fixture.basename.to_s,
      type:     'application/pdf'
    )

    amendment.upload = upload
    amendment.valid?
    refute_includes amendment.errors.details[:attachment], error: :bad_pdf
  end

  test 'should be auditable' do
    project   = projects(:one)
    amendment = project.project_amendments.build(requested_at: Time.zone.today)

    with_versioning do
      assert_auditable amendment
    end
  end

  test 'saving should increment project amendment number' do
    project   = projects(:one)
    amendment = project.project_amendments.build(requested_at: Time.zone.today)
    fixture = file_fixture('odr_amendment_request_form-1.0.pdf')
    upload  = ActionDispatch::Http::UploadedFile.new(
      tempfile: File.new(fixture, 'rb'),
      filename: fixture.basename.to_s,
      type:     'application/pdf'
    )
    amendment.upload = upload
    assert_changes -> { project.reload.amendment_number }, from: 0, to: 1 do
      amendment.save!
    end

    amendment = project.project_amendments.build(requested_at: Time.zone.today)
    amendment.upload = upload
    assert_changes -> { project.reload.amendment_number }, from: 1, to: 2 do
      amendment.save!
    end

    project.project_amendments.first.destroy

    amendment = project.project_amendments.build(requested_at: Time.zone.today)
    amendment.upload = upload
    assert_changes -> { project.reload.amendment_number }, from: 2, to: 3 do
      amendment.save!
    end
  end
end
