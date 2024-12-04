require 'test_helper'

# Tests the date validator
class DateValidatorTest < ActiveSupport::TestCase
  # ActiveModel for testing date validations
  class Timeline
    include ActiveModel::Validations

    EARLIEST_BIRTH_DATE = Date.new(1900, 1, 1)
    CHILD_REFERRAL_MSG = 'should not refer children'.freeze

    attr_accessor :birth_date, :referral_date, :treatment_date, :death_date

    validates :birth_date, date: { no_future: true,
                                   not_before: EARLIEST_BIRTH_DATE,
                                   not_after: :death_date }
    validates :referral_date, date: { message: CHILD_REFERRAL_MSG,
                                      not_before: ->(rec) { rec.birth_date + 10.years } }
    validates :treatment_date, date: { not_before: ->(rec) { rec.birth_date + 13.years } }
  end

  test 'should validate against future date' do
    timeline = Timeline.new
    timeline.birth_date = 3.years.since
    refute timeline.valid?
    assert_includes timeline.errors[:birth_date], I18n.t('errors.messages.no_future')

    timeline.birth_date = 3.years.ago
    assert timeline.valid?

    timeline.birth_date = Time.zone.today
    assert timeline.valid?
  end

  test 'should validate against not_after symbol' do
    timeline = Timeline.new
    timeline.birth_date = 3.years.ago
    timeline.death_date = 70.years.ago
    refute timeline.valid?
    error_message = I18n.t('errors.messages.not_after',
                           comparison: Timeline.human_attribute_name(:death_date))
    assert_includes timeline.errors[:birth_date], error_message

    timeline.birth_date = 70.years.ago
    timeline.death_date = 3.years.ago
    assert timeline.valid?
  end

  test 'should validate against not_before date' do
    timeline = Timeline.new
    timeline.birth_date = 130.years.ago
    refute timeline.valid?
    error_message = I18n.t('errors.messages.not_before',
                           comparison: Timeline::EARLIEST_BIRTH_DATE.to_fs(:ui))
    assert_includes timeline.errors[:birth_date], error_message

    timeline.birth_date = 70.years.ago
    assert timeline.valid?
  end

  test 'should validate against not_before proc with message' do
    timeline = Timeline.new
    timeline.birth_date = 20.years.ago
    timeline.referral_date = timeline.birth_date + 9.years
    refute timeline.valid?
    assert_includes timeline.errors[:referral_date], Timeline::CHILD_REFERRAL_MSG

    timeline.referral_date = timeline.birth_date + 11.years
    assert timeline.valid?
  end

  test 'should validate against not_before proc without message' do
    timeline = Timeline.new
    timeline.birth_date = 20.years.ago
    timeline.treatment_date = timeline.birth_date + 12.years
    refute timeline.valid?
    error_message = I18n.t('errors.messages.not_before',
                           comparison: 13.years.since(timeline.birth_date).to_fs(:ui))
    assert_includes timeline.errors[:treatment_date], error_message

    timeline.treatment_date = timeline.birth_date + 14.years
    assert timeline.valid?
  end
end
