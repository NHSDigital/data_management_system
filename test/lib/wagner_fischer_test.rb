require 'test_helper'

class WagnerFischerTest < ActiveSupport::TestCase
  setup do
    @wf = WagnerFischer.new('hello', 'cell') { |a, b| a == b }
  end

  test 'initialises with two sequences and a comparator' do
    assert_equal %w[h e l l o], @wf.seq_a
    assert_equal %w[c e l l], @wf.seq_b
  end

  test 'outputs a WF matrix' do
    matrix = [
      [0, 1, 2, 3, 4, 5],
      [1, 1, 2, 3, 4, 5],
      [2, 2, 1, 2, 3, 4],
      [3, 3, 2, 1, 2, 3],
      [4, 4, 3, 2, 1, 2]
    ]

    assert_equal matrix, @wf.matrix
  end

  test 'outputs an edit sequence' do
    edits = @wf.edit_sequence

    assert_equal 5, edits.length
    assert(edits.all? { |edit| edit.is_a? WagnerFischer::Edit })
  end

  test 'can draw the edit sequence' do
    assert_stdout(<<~SEQ) { @wf.draw }
      cell\s
      |===+ (2)
      hello
    SEQ
  end

  test 'works correctly' do
    assert_stdout(<<~SEQ) { WagnerFischer.new('Saturday', 'Sunday') { |a, b| a == b }.draw }
      S  unday
      =++=|=== (3)
      Saturday
    SEQ

    assert_stdout(<<~SEQ) { WagnerFischer.new('difficult', 'occultist') { |a, b| a == b }.draw }
         occultist
      +++||====--- (8)
      difficult\s\s\s
    SEQ

    assert_stdout(<<~SEQ) { WagnerFischer.new('', 'hello') { |a, b| a == b }.draw }
      hello
      ----- (5)
      \s\s\s\s\s
    SEQ

    assert_stdout(<<~SEQ) { WagnerFischer.new('hello', '') { |a, b| a == b }.draw }
      \s\s\s\s\s
      +++++ (5)
      hello
    SEQ
  end

  private

  def assert_stdout(expected)
    previous_stdout = $stdout
    $stdout = StringIO.new

    yield

    assert_equal expected, $stdout.string
  ensure
    $stdout = previous_stdout
  end
end
