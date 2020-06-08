module Pseudo
  # death record data
  # - inflection for singular/plural changed in config/initializers/inflections.rb
  class DeathData < ActiveRecord::Base
    belongs_to :ppatient

    validates :ppatient, presence: true

    # Numerics from M204
    # lower case letters from LEDR
    #  (-- 0 01 02 03 1` Y 5 6 7 9 41 92 are very rare, and only in older M204 data),
    COD10R_VALUES = %w[-- 0 01 02 03 1` Y 1 2 3 4 5 6 7 9 10 11 12 41 92 a b c d e].freeze
    RETIND_VALUES = %w[1 Y N].freeze # Numeric values from M204, strings from LEDR

    # PLOACC10 is supposed to be 1 numerical character (or blank)
    # but old (pre-2001) M204 deaths sometimes have value '@'.
    # and new (post-2018) LEDR deaths sometimes have values '10', '11'.
    PLOACC10_VALUES = %w[@ 0 1 2 3 4 5 6 7 8 9 10 11].freeze

    # Maps new (alphabetical) / old (numeric) COD10R values to old cancer death lineno values
    # On 16 Jan 2018, at 17:25, ONS wrote:
    # The data format is different in LEDR for fields COD10R_1 to COD10R_20 - we see lines
    # For routines
    # cod10r a = 1a - line 1
    # cod10r b = 1b - line 2
    # cod10r c = 1c - line 3
    # cod10r d & e - line 10 are concatenated in to part 2 in line with our death certificate for
    #                England and Wales.
    # For Neonatal Deaths and Stillbirths
    # cod10r a = a = line 1
    # cod10r b = b = line 2
    # cod10r c = c = line 10
    # cod10r d = d = line 11
    # cod10r e = e = line 12
    COD10R_TO_LINENO9 = { 'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4, 'e' => 4,
                          '1' => 1, '2' => 2, '3' => 3, '4' => 4, '10' => 4,
                          '11' => 6, '12' => 6 }.freeze

    class_eval do
      (1..20).each do |i|
        validates "cod10r_#{i}", inclusion: COD10R_VALUES, allow_nil: true
        validates "cod10rf_#{i}", inclusion: COD10R_VALUES, allow_nil: true
      end
    end

    validates "retindm", inclusion: RETIND_VALUES, allow_nil: true
    validates "retindhf", inclusion: RETIND_VALUES, allow_nil: true
    validates 'ploacc10', inclusion: PLOACC10_VALUES, allow_nil: true
  end
end
