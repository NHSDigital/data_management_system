require 'test_helper'
class CasApplicationFieldsTest < ActiveSupport::TestCase
  test 'handling `declaration` attribute' do
    choices = %w[1Yes 2No 4Yes]
    ca = CasApplicationFields.new(declaration: choices)
    assert_equal '1Yes,2No,4Yes', ca.declaration
    expected_hash = { '1' => 'Yes', '2' => 'No', '4' => 'Yes' }
    assert_equal expected_hash, ca.declaration_choices
  end

  test 'extra_datasets_rationale_must_be_populated_if_extra_datasets validation' do
    application = Project.new.tap do |app|
      app.owner = users(:no_roles)
      app.project_type = project_types(:cas)
      app.build_cas_application_fields(extra_datasets_rationale: nil)
      app.save!(validate: false)
    end
    default_project_dataset = ProjectDataset.new(dataset: Dataset.find_by(name: 'Cas Defaults Dataset'),
                                                 terms_accepted: true)
    application.project_datasets << default_project_dataset
    pdl = ProjectDatasetLevel.new(access_level_id: 1, selected: true,
                                  expiry_date: Time.zone.today + 2.months)
    default_project_dataset.project_dataset_levels << pdl

    application.cas_application_fields.valid?
    refute application.cas_application_fields.errors.messages[:extra_datasets_rationale].
      include? 'Dataset justification is required when selecting any datasets'

    extra_project_dataset = ProjectDataset.create(dataset: Dataset.
                                                             find_by(name: 'Extra CAS Dataset One'),
                                                  terms_accepted: true)
    application.project_datasets << extra_project_dataset
    pdl2 = ProjectDatasetLevel.new(access_level_id: 2, selected: nil,
                                   expiry_date: Time.zone.today + 2.months)
    extra_project_dataset.project_dataset_levels << pdl2

    application.cas_application_fields.valid?
    refute application.cas_application_fields.errors.messages[:extra_datasets_rationale].
      include? 'Dataset justification is required when selecting any datasets'

    pdl2.update(selected: true)
    extra_project_dataset.project_dataset_levels.reload

    application.cas_application_fields.valid?
    assert application.cas_application_fields.errors.messages[:extra_datasets_rationale].
      include? 'Dataset justification is required when selecting any datasets'

    application.cas_application_fields.update(extra_datasets_rationale: 'TESTING')

    application.cas_application_fields.valid?
    refute application.cas_application_fields.errors.messages[:extra_datasets_rationale].
      include? 'Dataset justification is required when selecting any datasets'
  end

  test 'reason_justification_must_be_populated_if_level_1_selected validation' do
    application = Project.new.tap do |app|
      app.owner = users(:no_roles)
      app.project_type = project_types(:cas)
      app.build_cas_application_fields(reason_justification: nil)
      app.save!(validate: false)
    end

    default_project_dataset = ProjectDataset.new(dataset: Dataset.find_by(name: 'Cas Defaults Dataset'),
                                                 terms_accepted: true)
    application.project_datasets << default_project_dataset
    level_2_pdl = ProjectDatasetLevel.new(access_level_id: 2, selected: true)
    default_project_dataset.project_dataset_levels << level_2_pdl

    application.cas_application_fields.valid?
    refute application.cas_application_fields.errors.messages[:reason_justification].
      include? 'Access level justification is required when selecting access level 1 for any ' \
               'dataset'

    level1_pdl = ProjectDatasetLevel.create(access_level_id: 1, selected: nil,
                                            expiry_date: Time.zone.now + 1.month,
                                            project_dataset_id: default_project_dataset.id)

    application.cas_application_fields.valid?
    refute application.cas_application_fields.errors.messages[:reason_justification].
      include? 'Access level justification is required when selecting access level 1 for any ' \
               'dataset'

    level1_pdl.update(selected: true)
    application.reload

    application.cas_application_fields.valid?
    assert application.cas_application_fields.errors.messages[:reason_justification].
      include? 'Access level justification is required when selecting access level 1 for any ' \
               'dataset'

    application.cas_application_fields.update(reason_justification: 'TESTING')

    application.cas_application_fields.valid?
    refute application.cas_application_fields.errors.messages[:reason_justification].
      include? 'Access level justification is required when selecting access level 1 for any ' \
               'dataset'
  end

  test 'must have all declarations set to yes' do
    application = Project.new.tap do |app|
      app.owner = users(:no_roles)
      app.project_type = project_types(:cas)
      default_project_dataset = ProjectDataset.create(dataset: Dataset.find_by(name: 'Cas Defaults Dataset'),
                                                      terms_accepted: true)
      app.project_datasets << default_project_dataset
      app.build_cas_application_fields(declaration: [])
      app.save!(validate: false)
    end

    application.cas_application_fields.valid?
    assert application.cas_application_fields.errors.messages[:declaration].
      include? 'All declarations must be yes before an application can be submitted'

    application.cas_application_fields.update(declaration: %w[1No 2No 3No 4No])
    application.cas_application_fields.valid?
    assert application.cas_application_fields.errors.messages[:declaration].
      include? 'All declarations must be yes before an application can be submitted'

    application.cas_application_fields.update(declaration: %w[1Yes 2No 3No 4No])
    application.cas_application_fields.valid?
    assert application.cas_application_fields.errors.messages[:declaration].
      include? 'All declarations must be yes before an application can be submitted'

    application.cas_application_fields.update(declaration: %w[1Yes 2Yes 4Yes])
    application.cas_application_fields.valid?
    assert application.cas_application_fields.errors.messages[:declaration].
      include? 'All declarations must be yes before an application can be submitted'

    application.cas_application_fields.update(declaration: %w[1Yes 2Yes 3Yes 4Yes])
    application.cas_application_fields.valid?
    refute application.cas_application_fields.errors.messages[:declaration].
      include? 'All declarations must be yes before an application can be submitted'
  end
end
