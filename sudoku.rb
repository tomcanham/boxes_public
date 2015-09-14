require 'set'

class SudokuError < RuntimeError
end

class NakedSingletonStrategy
  def solve(board)
    solved = []
    remaining = []

    (0..8).each do |row|
      (0..8).each do |col|
        candidates = board.candidates([row, col])
        if candidates.count == 1
          board.set([row, col], candidates.first)
          solved.push("#{board.friendly_name(row, col)} = #{candidates.first}")
        elsif candidates.count > 1
          remaining.push(board.friendly_name(row, col))
        end
      end
    end

    return solved, remaining
  end
end

# we need this to keep track of candidate counts
class CandidatesMap
  def initialize(board)
    @board = board
    reset

    (0..8).each do |row|
      (0..8).each do |col|
        if board.get([row, col])
          solve_cell(row, col, board.get([row, col]))
        end
      end
    end
  end

  def solve_cell(row, col, value)
    @row_candidates[row].delete(value)
    @col_candidates[col].delete(value)
    @box_candidates[Board.box_idx_for_row_col(row, col)].delete(value)
  end

  def candidates(row, col)
    if @board.get([row, col])
      Set.new
    else
      row_candidates = @row_candidates[row]
      col_candidates = @col_candidates[col]
      box_candidates = @box_candidates[Board.box_idx_for_row_col(row, col)]

      row_candidates & col_candidates & box_candidates
    end
  end

  def reset
    @row_candidates = Array.new(9) {Set.new(1..9)}
    @col_candidates = Array.new(9) {Set.new(1..9)}
    @box_candidates = Array.new(9) {Set.new(1..9)}
  end
end

class Board
  def initialize(serialized = nil)
    @values = Array.new(9) { Array.new(9) }
    @candidates_map = CandidatesMap.new(self)

    unless serialized.nil?
      deserialize(serialized)
    end    
  end

  def solve(strategy)
    strategy.solve(self)
  end

  def set(position_name, value)
    row, col = position_name_to_row_col(position_name)

    unless get_internal(row, col).nil?
      raise SudokuError.new("Cell #{position_name} is already solved")
    end

    unless candidates(position_name).include?(value)
      raise SudokuError.new("#{value.to_s} is not a valid value for cell #{position_name}. Valid values are #{candidates(position_name).to_a.join(', ')}.")
    end

    set_internal(row, col, value)
    @candidates_map.solve_cell(row, col, value)
  end

  def get(position_name)
    row, col = position_name_to_row_col(position_name)

    get_internal(row, col)
  end

  def candidates(position_name)
    row, col = position_name_to_row_col(position_name)

    @candidates_map.candidates(row, col)
  end

  def pretty_print
    row_chars = ('A'..'H').to_a+['J']

    puts "\n   " + (1..9).map {|i| " #{i} "}.join
    (0..8).each do |row|
      print " #{row_chars[row]} "
      (0..8).each do |col|
        print " #{@values[row][col] || '.'} "
      end
      puts
    end
  end

  def position_name_to_row_col(position_name)
    if position_name.instance_of?(Array)
      return position_name
    else
      row_name = position_name[0].upcase
      col_name = position_name[1]

      row_idx = (('A'..'H').to_a+['J']).index(row_name)
      col_idx = col_name.to_i - 1

      return row_idx, col_idx
    end
  end

  def ==(other)
    return other.instance_of?(Board) && (other.instance_variable_get(:@values) == @values)
  end

  def clone
    result = Board.new
    @values_clone = Array.new(9) {|row| @values[row].dup}

    result.instance_variable_set(:@values, @values_clone)

    result
  end

  def friendly_name(row, col)
    return board_positions[row][col]
  end

  def self.box_idx_for_row_col(row_idx, col_idx)
    row_offset = (row_idx / 3).floor * 3
    col_offset = (col_idx / 3).floor

    row_offset + col_offset
  end

  # honestly we probably don't need all these "XXX_internal methods, but I like to hide implementations"
  private
  def set_internal(row, col, value)
    @values[row][col] = value
    @candidates_map.solve_cell(row, col, value)
  end
  
  def get_internal(row, col)
    @values[row][col]
  end

  def box_for_row_col(row, col)
    row_offset = (row / 3).floor * 3
    col_offset = (col / 3).floor

    @boxes[Board.box_idx_for_row_col(row, col)]
  end

  def deserialize(serialized_board)
    chars = serialized_board.split('') # turns it into an 81-character array

    @candidates_map.reset
    (0..8).each do |row|
      (0..8).each do |col|
        this_val = chars[row * 9 + col]
        this_val = (this_val == '.') ? nil : this_val.to_i

        set_internal(row, col, this_val)
      end
    end
  end

  def board_positions
    # only do this the first time it's used
    if @board_positions.nil?
      # row 'I' is skipped because it's easy to confuse with the numeral '1'
      row_chars = ('A'..'H').to_a+['J']

      # build grid of cell names from 'A1' through 'J9'
      @board_positions = Array.new(9) { |y| Array.new(9) { |x| "#{row_chars[y]}#{x+1}" }}
    end

    @board_positions
  end
end