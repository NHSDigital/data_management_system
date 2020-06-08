require 'test_helper'

class PDFApplicationFacadeTest < ActiveSupport::TestCase
  def setup
    team    = teams(:team_one)
    project = team.projects.build(project_type: project_types(:application))
    @project = PDFApplicationFacade.new(project)
  end

  test 'should only be used with new projects' do
    assert_raises do
      PDFApplicationFacade.new(projects(:one))
    end
  end

  test 'should create a new project' do
    team = teams(:team_one)
    user = team.users.first

    # Realistically, an application would have a lot more data items, but I'm lazy...
    @project.applicant_first_name = user.first_name
    @project.applicant_surname    = user.last_name
    @project.applicant_email      = user.email
    @project.project_title        = 'PDF Application Test'
    @project.project_purpose      = 'To challenge my sanity'
    @project.project_start_date   = Time.zone.today

    assert_difference -> { team.projects.count } do
      @project.save
    end
  end

  test 'should be invalid if underlying project is invalid' do
    project = @project.project

    project.stubs(valid?: false)
    refute @project.valid?

    project.stubs(valid?: true)
    assert @project.valid?
  end

  test 'should ensure errors are syncronized' do
    @project.errors.expects(:merge!).with(@project.project.errors)
    @project.valid?
  end

  test 'should assign associated end uses' do
    project = @project.project

    assert_no_difference -> { project.end_uses.count } do
      assert_difference -> { project.end_uses.size } do
        @project.research = :Yes
        assert_includes project.end_uses, end_uses(:one)
      end
    end

    assert_no_difference -> { project.end_uses.count } do
      assert_no_difference -> { project.end_uses.size } do
        @project.service_evaluation = :Off
        refute_includes project.end_uses, end_uses(:two)
      end
    end
  end

  test 'should assign associated classifications' do
    project = @project.project

    assert_no_difference -> { project.classifications.count } do
      assert_difference -> { project.classifications.size } do
        @project.level_of_identifiability = :PersonallyIdentifiable
        assert_includes project.classifications, classifications(:three)
      end
    end
  end

  test 'should assign associated lawful bases' do
    project = @project.project

    assert_no_difference -> { project.lawful_bases.count } do
      assert_difference -> { project.lawful_bases.size } do
        @project.article_6a = :Yes
        assert_includes project.lawful_bases, lookups_lawful_basis(:'6.1a')
      end
    end

    assert_no_difference -> { project.lawful_bases.count } do
      assert_no_difference -> { project.lawful_bases.size } do
        @project.article_9b = :Off
        refute_includes project.lawful_bases, lookups_lawful_basis(:'9.2b')
      end
    end
  end

  test 'should assign security assurance' do
    project = @project.project

    assert_changes -> { project.security_assurance } do
      @project.security_assurance_applicant = 'IGToolkitApplicant'
      assert_equal lookups_security_assurance(:dsp_toolkit), project.security_assurance
    end

    assert_changes -> { project.security_assurance_outsourced } do
      @project.security_assurance_outsourced = 'SLSPOutsourced'
      assert_equal lookups_security_assurance(:slsp), project.security_assurance_outsourced
    end
  end

  test 'should assign processing territory' do
    project = @project.project

    assert_changes -> { project.processing_territory } do
      @project.processing_territory = 'UK'
      assert_equal lookups_processing_territory(:uk), project.processing_territory
    end

    assert_changes -> { project.processing_territory_outsourced } do
      @project.processing_territory_outsourced = 'EEA'
      assert_equal lookups_processing_territory(:eea), project.processing_territory_outsourced
    end
  end

  test 'should create a new user resource' do
    Project.any_instance.stubs(valid?: true)

    @project.applicant_first_name = 'Johann'
    @project.applicant_surname    = 'Blogs'
    @project.applicant_email      = 'johann.blogs@example.com'
    @project.applicant_telephone  = '0123456789'
    @project.applicant_job_title  = 'Barista'

    assert_difference -> { User.count } do
      assert_difference -> { @project.team.users.count } do
        @project.save
      end
    end

    user = User.order(:created_at).last

    assert_equal @project.applicant_first_name, user.first_name
    assert_equal @project.applicant_surname,    user.last_name
    assert_equal @project.applicant_email,      user.email
    assert_equal @project.applicant_telephone,  user.telephone
    assert_equal @project.applicant_job_title,  user.job_title
  end

  test 'should update existing user resources' do
    Project.any_instance.stubs(valid?: true)

    team = @project.team
    user = team.users.first

    @project.applicant_first_name = user.first_name
    @project.applicant_surname    = user.last_name
    @project.applicant_email      = user.email
    @project.applicant_telephone  = '0123456789'
    @project.applicant_job_title  = 'Barista'

    assert_no_difference -> { User.count } do
      assert_no_difference -> { team.users.count } do
        @project.save
      end
    end

    user.reload

    assert_equal @project.applicant_first_name, user.first_name
    assert_equal @project.applicant_surname,    user.last_name
    assert_equal @project.applicant_email,      user.email
    assert_equal @project.applicant_telephone,  user.telephone
    assert_equal @project.applicant_job_title,  user.job_title
  end

  test 'should correctly cast acroform booleans' do
    @project.data_to_contact_others = :Off
    refute @project.data_to_contact_others

    @project.data_to_contact_others = :Yes
    assert @project.data_to_contact_others
  end

  test 'should set project end date' do
    @project.project_start_date = Time.zone.today
    @project.duration           = 12

    assert_changes -> { @project.end_data_date } do
      @project.save
      assert_equal 1.year.from_now.at_beginning_of_day, @project.end_data_date
    end
  end

  test 'should complete sponsor organisation fields when same as applicant organisation' do
    @project.sponsor_same_as_applicant = true
    @project.save

    assert_equal @project.sponsor_name,       @project.organisation.name
    assert_equal @project.sponsor_add1,       @project.organisation.add1
    assert_equal @project.sponsor_add2,       @project.organisation.add2
    assert_equal @project.sponsor_city,       @project.organisation.city
    assert_equal @project.sponsor_postcode,   @project.organisation.postcode
    assert_equal @project.sponsor_country_id, @project.organisation.country_id
  end

  test 'should not complete sponsor organisation fields when not same as applicant organisation' do
    @project.sponsor_same_as_applicant = false
    @project.save

    refute_equal @project.sponsor_name,       @project.organisation.name
    refute_equal @project.sponsor_add1,       @project.organisation.add1
    refute_equal @project.sponsor_add2,       @project.organisation.add2
    refute_equal @project.sponsor_city,       @project.organisation.city
    refute_equal @project.sponsor_postcode,   @project.organisation.postcode
    refute_equal @project.sponsor_country_id, @project.organisation.country_id
  end

  test 'should complete funder organisation fields when same as applicant organisation' do
    @project.funder_same_as_applicant = true
    @project.save

    assert_equal @project.funder_name,       @project.organisation.name
    assert_equal @project.funder_add1,       @project.organisation.add1
    assert_equal @project.funder_add2,       @project.organisation.add2
    assert_equal @project.funder_city,       @project.organisation.city
    assert_equal @project.funder_postcode,   @project.organisation.postcode
    assert_equal @project.funder_country_id, @project.organisation.country_id
  end

  test 'should not complete funder organisation fields when not same as applicant organisation' do
    @project.funder_same_as_applicant = false
    @project.save

    refute_equal @project.funder_name,       @project.organisation.name
    refute_equal @project.funder_add1,       @project.organisation.add1
    refute_equal @project.funder_add2,       @project.organisation.add2
    refute_equal @project.funder_city,       @project.organisation.city
    refute_equal @project.funder_postcode,   @project.organisation.postcode
    refute_equal @project.funder_country_id, @project.organisation.country_id
  end
end
