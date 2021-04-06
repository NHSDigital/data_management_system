require 'test_helper'

class PDFApplicationFacadeTest < ActiveSupport::TestCase
  def setup
    team = teams(:team_one)
    @project = team.projects.build(project_type: project_types(:application))
    @facade = PdfApplicationFacade.new(@project)
  end

  test 'should only be used with new projects' do
    assert_raises do
      PdfApplicationFacade.new(projects(:one))
    end
  end

  test 'should create a new project' do
    team = teams(:team_one)
    user = team.users.first

    # Realistically, an application would have a lot more data items, but I'm lazy...
    @facade.applicant_first_name = user.first_name
    @facade.applicant_surname    = user.last_name
    @facade.applicant_email      = user.email
    @facade.project_title        = 'PDF Application Test'
    @facade.project_purpose      = 'To challenge my sanity'
    @facade.project_start_date   = Time.zone.today

    assert_difference -> { team.projects.count } do
      @facade.save
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

    assert_no_difference -> { project.end_uses.count } do
      assert_difference -> { project.end_uses.size } do
        @facade.research = :Yes
        assert_includes project.end_uses, end_uses(:one)
      end
    end

    assert_no_difference -> { project.end_uses.count } do
      assert_no_difference -> { project.end_uses.size } do
        @facade.service_evaluation = :Off
        refute_includes project.end_uses, end_uses(:two)
      end
    end
  end

  test 'should assign associated classifications' do
    project = @facade.project

    assert_no_difference -> { project.classifications.count } do
      assert_difference -> { project.classifications.size } do
        @facade.level_of_identifiability = :PersonallyIdentifiable
        assert_includes project.classifications, classifications(:three)
      end
    end
  end

  test 'should assign associated lawful bases' do
    project = @facade.project

    assert_no_difference -> { project.lawful_bases.count } do
      assert_difference -> { project.lawful_bases.size } do
        @facade.article_6a = :Yes
        assert_includes project.lawful_bases, lookups_lawful_basis(:'6.1a')
      end
    end

    assert_no_difference -> { project.lawful_bases.count } do
      assert_no_difference -> { project.lawful_bases.size } do
        @facade.article_9b = :Off
        refute_includes project.lawful_bases, lookups_lawful_basis(:'9.2b')
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
    @facade.update(name: 'blah', owner: users(:standard_user), organisation_add1: '134',
                   organisation_add2: 'Test Lane', organisation_city: 'Testville',
                   organisation_postcode: 'T3ST 1NG', organisation_country: 'UNITED KINGDOM')
    @facade.sponsor_same_as_applicant = true
    @facade.organisation_name = 'Test Org Name'
    @facade.save

    assert_equal @facade.sponsor_name,       'Test Org Name'
    assert_equal @facade.sponsor_add1,       '134'
    assert_equal @facade.sponsor_add2,       'Test Lane'
    assert_equal @facade.sponsor_city,       'Testville'
    assert_equal @facade.sponsor_postcode,   'T3ST 1NG'
    assert_equal @facade.sponsor_country_id, 'XKU'
  end

  test 'should not complete sponsor organisation fields when not same as applicant organisation' do
    @facade.update(name: 'blah', owner: users(:standard_user), organisation_add1: '134',
                   organisation_add2: 'Test Lane', organisation_city: 'Testville',
                   organisation_postcode: 'T3ST 1NG', organisation_country: 'UNITED KINGDOM')
    @facade.sponsor_same_as_applicant = false
    @facade.organisation_name = 'Test Org Name'
    @facade.save

    refute_equal @facade.sponsor_name,       'Test Org Name'
    refute_equal @facade.sponsor_add1,       '134'
    refute_equal @facade.sponsor_add2,       'Test Lane'
    refute_equal @facade.sponsor_city,       'Testville'
    refute_equal @facade.sponsor_postcode,   'T3ST 1NG'
    refute_equal @facade.sponsor_country_id, 'XKU'
  end

  test 'should complete funder organisation fields when same as applicant organisation' do
    @facade.update(name: 'blah', owner: users(:standard_user), organisation_add1: '134',
                   organisation_add2: 'Test Lane', organisation_city: 'Testville',
                   organisation_postcode: 'T3ST 1NG', organisation_country: 'UNITED KINGDOM')
    @facade.funder_same_as_applicant = true
    @facade.organisation_name = 'Test Org Name'
    @facade.save

    assert_equal @facade.funder_name,       'Test Org Name'
    assert_equal @facade.funder_add1,       '134'
    assert_equal @facade.funder_add2,       'Test Lane'
    assert_equal @facade.funder_city,       'Testville'
    assert_equal @facade.funder_postcode,   'T3ST 1NG'
    assert_equal @facade.funder_country_id, 'XKU'
  end

  test 'should not complete funder organisation fields when not same as applicant organisation' do
    @facade.update(name: 'blah', owner: users(:standard_user), organisation_add1: '134',
                   organisation_add2: 'Test Lane', organisation_city: 'Testville',
                   organisation_postcode: 'T3ST 1NG', organisation_country: 'UNITED KINGDOM')
    @facade.funder_same_as_applicant = false
    @facade.organisation_name = 'Test Org Name'
    @facade.save

    refute_equal @facade.funder_name,       'Test Org Name'
    refute_equal @facade.funder_add1,       '134'
    refute_equal @facade.funder_add2,       'Test Lane'
    refute_equal @facade.funder_city,       'Testville'
    refute_equal @facade.funder_postcode,   'T3ST 1NG'
    refute_equal @facade.funder_country_id, 'XKU'
  end

  test 'should set sponsor country if id provided instead of country name' do
    @facade.update(organisation_country: 'XKU')
    @facade.sponsor_same_as_applicant = true
    @facade.save

    assert_equal @facade.sponsor_country_id, 'XKU'
  end

  test 'should set country if id provided instead of country name' do
    @facade.update(organisation_country: 'XKU')
    @facade.funder_same_as_applicant = true
    @facade.save

    assert_equal @facade.funder_country_id, 'XKU'
  end

  test 'should map incoming pdf level_of_identifiability symbol into correct mapped string' do
    @facade.level_of_identifiability = :PersonallyIdentifiable

    assert_equal 'Personally Identifiable', @project.level_of_identifiability
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
end
