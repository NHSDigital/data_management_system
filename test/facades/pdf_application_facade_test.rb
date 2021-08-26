require 'test_helper'

class PDFApplicationFacadeTest < ActiveSupport::TestCase
  def setup
    @team      = teams(:team_one)
    @applicant = users(:standard_user2)
    @project   = @team.projects.build(project_type: project_types(:application))
    @facade    = PdfApplicationFacade.new(@project)
  end

  test 'should create a new project' do
    assert_difference -> { @team.projects.count } do
      with_minimal_viable_data(@facade, @applicant) do
        @facade.save
      end
    end
  end

  test 'should update an existing project' do
    project = projects(:one)
    facade  = PdfApplicationFacade.new(project)

    assert_no_difference -> { @team.projects.count } do
      assert_changes -> { project.updated_at } do
        facade.project_title = 'Updated PDF Project Test'
        facade.save

        assert_equal 'Updated PDF Project Test', project.name
      end
    end
  end

  test 'updating a project should not create new applicant' do
    project = projects(:one)
    facade  = PdfApplicationFacade.new(project)

    assert_no_difference -> { User.count } do
      facade.applicant_email = 'scooby.doo@example.com'
      facade.save
    end
  end

  test 'updating a project should not change applicant details' do
    project = projects(:one)
    owner   = project.owner
    facade  = PdfApplicationFacade.new(project)

    assert_no_changes -> { owner.reload.first_name } do
      facade.applicant_first_name = owner.first_name.reverse
      facade.save
    end
  end

  test 'updating a project should not change organisation details' do
    project = projects(:one)
    facade  = PdfApplicationFacade.new(project)

    facade.organisation_department = 'New Dept.'
    facade.organisation_name       = 'New Inc.'
    facade.organisation_add1       = 'New Addy 1'
    facade.organisation_add2       = 'New Addy 2'
    facade.organisation_city       = 'New Jack City'
    facade.organisation_postcode   = 'AA11 1AA'
    facade.organisation_country    = 'ABW'
    facade.organisation_country_id = 'ABW'

    facade.save
    project.reload

    refute_equal 'New Dept.',     project.organisation_department
    refute_equal 'New Inc.',      project.organisation_name
    refute_equal 'New Addy 1',    project.organisation_add1
    refute_equal 'New Addy 2',    project.organisation_add2
    refute_equal 'New Jack City', project.organisation_city
    refute_equal 'AA11 1AA',      project.organisation_postcode
    refute_equal 'ABW',           project.organisation_country
    refute_equal 'ABW',           project.organisation_country_id
  end

  test 'updating a project should allow changes to sponsor/funder organisation' do
    project = projects(:one)

    project.update!(
      organisation_add1:       project.organisation.add1,
      organisation_add2:       project.organisation.add2,
      organisation_city:       project.organisation.city,
      organisation_postcode:   project.organisation.postcode,
      organisation_country:    project.organisation.country.value,
      organisation_country_id: project.organisation.country_id,
      sponsor_name:            'Previous Sponsor Inc.',
      sponsor_add1:            'Previous Sponsor Addy 1',
      sponsor_add2:            'Previous Sponsor Addy 2',
      sponsor_city:            'Previous Sponsor City',
      sponsor_postcode:        'BB22 2BB',
      sponsor_country_id:      'AFG',
      funder_name:             'Previous Funder Inc.',
      funder_add1:             'Previous Funder Addy 1',
      funder_add2:             'Previous Funder Addy 2',
      funder_city:             'Previous Funder City',
      funder_postcode:         'BB22 2BB',
      funder_country_id:       'AFG'
    )

    facade = PdfApplicationFacade.new(project)

    facade.organisation_name        = 'New Inc.'
    facade.organisation_add1        = 'New Addy 1'
    facade.organisation_add2        = 'New Addy 2'
    facade.organisation_city        = 'New Jack City'
    facade.organisation_postcode    = 'AA11 1AA'
    facade.organisation_country     = 'ABW'
    facade.organisation_country_id  = 'ABW'

    facade.sponsor_name             = 'New Sponsor Inc.'
    facade.sponsor_add1             = 'New Sponsor Addy 1'
    facade.sponsor_add2             = 'New Sponsor Addy 2'
    facade.sponsor_city             = 'New Sponsor City'
    facade.sponsor_postcode         = 'CC33 3CC'
    facade.sponsor_country          = 'AGO'

    facade.funder_same_as_applicant = true

    facade.save

    assert_equal 'New Sponsor Inc.',              project.sponsor_name
    assert_equal 'New Sponsor Addy 1',            project.sponsor_add1
    assert_equal 'New Sponsor Addy 2',            project.sponsor_add2
    assert_equal 'New Sponsor City',              project.sponsor_city
    assert_equal 'CC33 3CC',                      project.sponsor_postcode
    assert_equal 'AGO',                           project.sponsor_country_id

    refute_equal 'New Inc.',                      project.funder_name
    refute_equal 'New Addy 1',                    project.funder_add1
    refute_equal 'New Addy 2',                    project.funder_add2
    refute_equal 'New Jack City',                 project.funder_city
    refute_equal 'AA11 1AA',                      project.funder_postcode
    refute_equal 'ABW',                           project.funder_country_id

    assert_equal project.organisation_name,       project.funder_name
    assert_equal project.organisation_add1,       project.funder_add1
    assert_equal project.organisation_add2,       project.funder_add2
    assert_equal project.organisation_city,       project.funder_city
    assert_equal project.organisation_postcode,   project.funder_postcode
    assert_equal project.organisation_country_id, project.funder_country_id
  end

  test 'updating a project should not change attributes marked as read-only' do
    project = projects(:one)
    facade  = PdfApplicationFacade.new(project)

    assert_no_changes -> { project[:application_log] } do
      facade.application_log = SecureRandom.hex
      facade.save
    end
  end

  test 'should be invalid if underlying project is invalid' do
    project = @facade.project

    project.stubs(valid?: false)
    refute @facade.valid?

    project.stubs(valid?: true)
    assert @facade.valid?
  end

  test 'should ensure errors are syncronized' do
    @facade.errors.expects(:merge!).with(@facade.project.errors)
    @facade.valid?
  end

  test 'should assign associated end uses' do
    project = @facade.project
    end_use = end_uses(:one)

    with_minimal_viable_data(@facade, @applicant) do
      @facade.research = :Yes

      assert_includes @facade.end_uses, end_use
      refute_includes project.end_uses, end_use

      assert_difference -> { project.end_uses.count } do
        @facade.save
        assert_includes project.end_uses, end_use
      end

      @facade.research = :Off

      refute_includes @facade.end_uses, end_use
      assert_includes project.end_uses, end_use

      assert_difference -> { project.end_uses.count }, -1 do
        @facade.save
        refute_includes project.end_uses, end_use
      end
    end
  end

  test 'should assign associated classifications' do
    project = @facade.project
    classification = classifications(:three)

    with_minimal_viable_data(@facade, @applicant) do
      @facade.level_of_identifiability = :PersonallyIdentifiable

      assert_includes @facade.classifications, classification
      refute_includes project.classifications, classification

      assert_difference -> { project.classifications.count } do
        @facade.save
        assert_includes project.classifications, classification
      end

      assert_nothing_raised do
        @facade.level_of_identifiability = :Fail
        @facade.save
      end
    end
  end

  test 'should assign associated lawful bases' do
    project = @facade.project
    basis   = lookups_lawful_basis(:'6.1a')

    with_minimal_viable_data(@facade, @applicant) do
      @facade.article_6a = :Yes

      assert_includes @facade.lawful_bases, basis
      refute_includes project.lawful_bases, basis

      assert_difference -> { project.lawful_bases.count } do
        @facade.save
        assert_includes project.lawful_bases, basis
      end

      @facade.article_6a = :Off

      refute_includes @facade.lawful_bases, basis
      assert_includes project.lawful_bases, basis

      assert_difference -> { project.lawful_bases.count }, -1 do
        @facade.save
        refute_includes project.lawful_bases, basis
      end
    end
  end

  test 'should assign security assurance' do
    project = @facade.project

    assert_changes -> { project.security_assurance } do
      @facade.security_assurance_applicant = 'IGToolkitApplicant'
      assert_equal lookups_security_assurance(:dsp_toolkit), project.security_assurance
    end

    assert_changes -> { project.security_assurance_outsourced } do
      @facade.security_assurance_outsourced = 'SLSPOutsourced'
      assert_equal lookups_security_assurance(:slsp), project.security_assurance_outsourced
    end
  end

  test 'should assign processing territory' do
    project = @facade.project

    assert_changes -> { project.processing_territory } do
      @facade.processing_territory = 'UK'
      assert_equal lookups_processing_territory(:uk), project.processing_territory
    end

    assert_changes -> { project.processing_territory_outsourced } do
      @facade.processing_territory_outsourced = 'EEA'
      assert_equal lookups_processing_territory(:eea), project.processing_territory_outsourced
    end
  end

  test 'should create a new user resource' do
    Project.any_instance.stubs(valid?: true)

    @facade.applicant_first_name = 'Johann'
    @facade.applicant_surname    = 'Blogs'
    @facade.applicant_email      = 'johann.blogs@example.com'
    @facade.applicant_telephone  = '0123456789'
    @facade.applicant_job_title  = 'Barista'

    assert_difference -> { User.count } do
      assert_difference -> { @facade.team.users.count } do
        @facade.save
      end
    end

    user = User.order(:created_at).last

    assert_equal @facade.applicant_first_name, user.first_name
    assert_equal @facade.applicant_surname,    user.last_name
    assert_equal @facade.applicant_email,      user.email
    assert_equal @facade.applicant_telephone,  user.telephone
    assert_equal @facade.applicant_job_title,  user.job_title
  end

  test 'should update existing user resources' do
    Project.any_instance.stubs(valid?: true)

    team = @facade.team
    user = team.users.first

    @facade.applicant_first_name = user.first_name
    @facade.applicant_surname    = user.last_name
    @facade.applicant_email      = user.email
    @facade.applicant_telephone  = '0123456789'
    @facade.applicant_job_title  = 'Barista'

    assert_no_difference -> { User.count } do
      assert_no_difference -> { team.users.count } do
        @facade.save
      end
    end

    user.reload

    assert_equal @facade.applicant_first_name, user.first_name
    assert_equal @facade.applicant_surname,    user.last_name
    assert_equal @facade.applicant_email,      user.email
    assert_equal @facade.applicant_telephone,  user.telephone
    assert_equal @facade.applicant_job_title,  user.job_title
  end

  test 'should correctly cast acroform booleans' do
    @facade.data_to_contact_others = :Off
    refute @facade.data_to_contact_others

    @facade.data_to_contact_others = :Yes
    assert @facade.data_to_contact_others
  end

  test 'should set project end date' do
    @facade.project_start_date = Time.zone.today
    @facade.duration           = 12

    assert_changes -> { @facade.end_data_date } do
      @facade.save
      assert_equal 1.year.from_now.at_beginning_of_day, @facade.end_data_date
    end
  end

  test 'should complete sponsor organisation fields when same as applicant organisation' do
    with_minimal_viable_data(@facade, @applicant) do
      @facade.assign_attributes(
        organisation_name:     'Test Org Name',
        organisation_add1:     '134',
        organisation_add2:     'Test Lane',
        organisation_city:     'Testville',
        organisation_postcode: 'T3ST 1NG',
        organisation_country:  'UNITED KINGDOM'
      )

      @facade.sponsor_same_as_applicant = true
      @facade.save

      assert_equal 'Test Org Name', @facade.sponsor_name
      assert_equal '134',           @facade.sponsor_add1
      assert_equal 'Test Lane',     @facade.sponsor_add2
      assert_equal 'Testville',     @facade.sponsor_city
      assert_equal 'T3ST 1NG',      @facade.sponsor_postcode
      assert_equal 'XKU',           @facade.sponsor_country_id
    end
  end

  test 'should not complete sponsor organisation fields when not same as applicant organisation' do
    with_minimal_viable_data(@facade, @applicant) do
      @facade.assign_attributes(
        organisation_name:     'Test Org Name',
        organisation_add1:     '134',
        organisation_add2:     'Test Lane',
        organisation_city:     'Testville',
        organisation_postcode: 'T3ST 1NG',
        organisation_country:  'UNITED KINGDOM'
      )

      @facade.sponsor_same_as_applicant = false
      @facade.save

      refute_equal 'Test Org Name', @facade.sponsor_name
      refute_equal '134',           @facade.sponsor_add1
      refute_equal 'Test Lane',     @facade.sponsor_add2
      refute_equal 'Testville',     @facade.sponsor_city
      refute_equal 'T3ST 1NG',      @facade.sponsor_postcode
      refute_equal 'XKU',           @facade.sponsor_country_id
    end
  end

  test 'should complete funder organisation fields when same as applicant organisation' do
    with_minimal_viable_data(@facade, @applicant) do
      @facade.assign_attributes(
        organisation_name:     'Test Org Name',
        organisation_add1:     '134',
        organisation_add2:     'Test Lane',
        organisation_city:     'Testville',
        organisation_postcode: 'T3ST 1NG',
        organisation_country:  'UNITED KINGDOM'
      )

      @facade.funder_same_as_applicant = true
      @facade.save

      assert_equal 'Test Org Name', @facade.funder_name
      assert_equal '134',           @facade.funder_add1
      assert_equal 'Test Lane',     @facade.funder_add2
      assert_equal 'Testville',     @facade.funder_city
      assert_equal 'T3ST 1NG',      @facade.funder_postcode
      assert_equal 'XKU',           @facade.funder_country_id
    end
  end

  test 'should not complete funder organisation fields when not same as applicant organisation' do
    with_minimal_viable_data(@facade, @applicant) do
      @facade.assign_attributes(
        organisation_name:     'Test Org Name',
        organisation_add1:     '134',
        organisation_add2:     'Test Lane',
        organisation_city:     'Testville',
        organisation_postcode: 'T3ST 1NG',
        organisation_country:  'UNITED KINGDOM'
      )

      @facade.funder_same_as_applicant = false
      @facade.save

      refute_equal 'Test Org Name', @facade.funder_name
      refute_equal '134',           @facade.funder_add1
      refute_equal 'Test Lane',     @facade.funder_add2
      refute_equal 'Testville',     @facade.funder_city
      refute_equal 'T3ST 1NG',      @facade.funder_postcode
      refute_equal 'XKU',           @facade.funder_country_id
    end
  end

  test 'should set sponsor country if id provided instead of country name' do
    @facade.organisation_country      = 'XKU'
    @facade.sponsor_same_as_applicant = true
    @facade.save

    assert_equal 'XKU', @facade.sponsor_country_id
  end

  test 'should set country if id provided instead of country name' do
    @facade.organisation_country     = 'XKU'
    @facade.funder_same_as_applicant = true
    @facade.save

    assert_equal 'XKU', @facade.funder_country_id
  end

  test 'should map incoming pdf level_of_identifiability symbol into correct mapped string' do
    @facade.level_of_identifiability = :PersonallyIdentifiable

    assert_equal 'Personally Identifiable', @project.level_of_identifiability
  end

  test 'should map incoming pdf statuatory exemption' do
    @facade.s251_exemption = incoming_value = 'Regulation 2'
    assert_equal incoming_value, @facade.s251_exemption
    assert_equal lookups_common_law_exemption(:regulation_two), @project.s251_exemption

    @facade.s251_exemption = incoming_value = 'Informed Consent'
    assert_equal incoming_value, @facade.s251_exemption
    assert_equal lookups_common_law_exemption(:informed_consent), @project.s251_exemption

    @facade.s251_exemption = incoming_value = 'Not in lookup'
    assert_equal incoming_value, @facade.s251_exemption
    assert_nil @project.s251_exemption
  end

  test 'should populate programme_support_id field with value from lookup' do
    # can handle nils
    @facade.programme_support_id = nil

    assert_nil @project.programme_support_id

    @facade.programme_support_id = 'Yes'

    assert_equal 1, @project.programme_support_id

    @facade.programme_support_id = 'Y'

    assert_equal 1, @project.programme_support_id

    @facade.programme_support_id = 'No'

    assert_equal 2, @project.programme_support_id

    @facade.programme_support_id = 'N'

    assert_equal 2, @project.programme_support_id

    @facade.programme_support_id = 'Off'

    assert_equal 2, @project.programme_support_id

    @facade.programme_support_id = 'Not applicable'

    assert_equal 3, @project.programme_support_id
  end

  private

  def with_minimal_viable_data(facade, user)
    # Realistically, an application would have a lot more data items, but I'm lazy...
    facade.assign_attributes(
      applicant_first_name: user.first_name,
      applicant_surname:    user.last_name,
      applicant_email:      user.email,
      project_title:        'PDF Application Test',
      project_purpose:      'To challenge my sanity',
      project_start_date:   Time.zone.today
    )

    yield
  end
end
