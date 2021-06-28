require 'test_helper'

# Tests the Report::Base class
module Report
  class ReportTest < ActiveSupport::TestCase
    def setup
      @report = Report::Base.new
    end

    test 'returns a list of column names' do
      Base.stubs columns: [
        { label: 'FIRST',  accessor: :attribute1 },
        { label: 'SECOND', accessor: :attribute2 }
      ]

      assert_equal %w[FIRST SECOND], @report.column_labels
    end

    test 'should iterate through relation' do
      Base.stubs columns: [
        { label: 'UPPER',   accessor: :upcase },
        { label: 'LENGTH',  accessor: :length }
      ]

      @report.stubs(relation: %w[record1 record10])

      yields = 0

      @report.each do |entity, columns|
        yields += 1

        case entity
        when 'record1'
          assert_equal 'RECORD1', columns.first
          assert_equal 7, columns.last
        when 'record10'
          assert_equal 'RECORD10', columns.first
          assert_equal 8, columns.last
        else
          flunk 'unexpected entity!'
        end
      end

      assert_equal 2, yields
    end

    test 'should return a CSV including header' do
      Base.stubs columns: [
        { label: 'LENGTH',  accessor: :length },
        { label: 'REVERSE', accessor: :reverse }
      ]

      @report.stubs(relation: %w[record1 record10])

      data = CSV.parse(@report.to_csv)

      assert_equal %w[LENGTH REVERSE], data[0]
      assert_equal %w[7 1drocer],      data[1]
      assert_equal %w[8 01drocer],     data[2]
    end

    test 'should allow callable objects as column accessors' do
      Base.stubs columns: [
        { label: 'CALLABLE', accessor: ->(object) { object.upcase.reverse } }
      ]

      @report.stubs(relation: %w[record1 record10])

      data = CSV.parse(@report.to_csv)

      assert_equal ['CALLABLE'], data[0]
      assert_equal ['1DROCER'],  data[1]
      assert_equal ['01DROCER'], data[2]
    end

    test 'should allow values to be formatted' do
      Base.stubs columns: [
        { label: 'ATTR1', accessor: :itself, format: %i[upper reverse] },
        { label: 'ATTR2', accessor: :itself, format: :upper }
      ]

      @report.stubs(
        formatters: {
          lower:   ->(object) { object.downcase },
          upper:   ->(object) { object.upcase   },
          reverse: ->(object) { object.reverse  }
        }
      )

      @report.stubs(relation: %w[record1 record10])

      data = CSV.parse(@report.to_csv)

      assert_equal %w[ATTR1 ATTR2],       data[0]
      assert_equal %w[1DROCER RECORD1],   data[1]
      assert_equal %w[01DROCER RECORD10], data[2]
    end

    test 'should generate a filename for a report download' do
      travel_to Date.new(2021, 6, 22) do
        assert_equal 'base_20210622', @report.filename
      end
    end
  end
end
