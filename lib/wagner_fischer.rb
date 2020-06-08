# Implements the Wagner-Fischer approach to calculating the Levenshtein distance,
# and exposes the series of additions / deletions / substitions required for it.
class WagnerFischer
  # Object to represent a step in the sequence of modifications.
  class Edit
    attr_accessor :a, :b, :op
    def initialize(a, b, op)
      @a = a
      @b = b
      @op = op
    end
  end

  # The two sequences:
  attr_reader :seq_a, :seq_b

  # The method by which sequence members should be compared
  # for equality:
  attr_reader :comparator

  # The matrix used by the W-F approach to compute the Levenshtein distance:
  attr_reader :matrix

  # The series of moves across the matrix that represents achieving the LD:
  attr_reader :edit_sequence

  def initialize(target, source, &comparator)
    @seq_a = target.is_a?(String) ? target.chars : target
    @seq_b = source.is_a?(String) ? source.chars : source
    @comparator = comparator
    @matrix = compute_matrix
    @edit_sequence = compute_edit_sequence
  end

  def draw
    lines = ['', '', '']

    edit_sequence.each do |e|
      lines[0] << ('+' == e.op ? ' ' : e.a.to_s)
      lines[2] << ('-' == e.op ? ' ' : e.b.to_s)

      lines[1] << e.op
    end

    lines[1] << " (#{matrix[seq_b.length][seq_a.length]})"

    puts lines
  end

  private

  def compute_edit_sequence
    sequence = []
    add_to_sequence(sequence, seq_b.length, seq_a.length)
    sequence
  end

  def add_to_sequence(sequence, i, j)
    return if i == 0 and j == 0

    current   = matrix[i][j]
    deletion  = matrix[i - 1][j]     if i > 0
    insertion = matrix[i][j - 1]     if j > 0
    same      = matrix[i - 1][j - 1] if i > 0 and j > 0

    case [deletion, insertion, same].compact.min
    when same
      i -= 1
      j -= 1

      if same < current
        sequence.unshift(Edit.new(seq_b[i], seq_a[j], '|'))
      else
        sequence.unshift(Edit.new(seq_b[i], seq_a[j], '='))
      end
    when deletion
      i -= 1
      sequence.unshift(Edit.new(seq_b[i], nil, '-'))
    when insertion
      j -= 1
      sequence.unshift(Edit.new(nil, seq_a[j], '+'))
    end

    add_to_sequence(sequence, i, j)
  end

  def compute_matrix
    d = Array.new(seq_b.length + 1) { Array.new(seq_a.length + 1) }

    (0..seq_b.length).each { |i| d[i][0] = i }
    (0..seq_a.length).each { |j| d[0][j] = j }

    (1..seq_a.length).each do |j|
      (1..seq_b.length).each do |i|
        d[i][j] =
          if comparator.call(seq_b[i - 1], seq_a[j - 1])
            d[i - 1][j - 1]
          else
            1 + [d[i - 1][j], d[i][j - 1], d[i - 1][j - 1]].min
          end
      end
    end

    d
  end
end
