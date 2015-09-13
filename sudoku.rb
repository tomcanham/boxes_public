require 'set'

class SudokuError < RuntimeError
end

class NakedSingletonStrategy
  def solve(board)
    solved = []
    remaining = []

    board = board.clone
    (0..8).each do |row|
      (0..8).each do |col|
        if board.get([row, col]).nil?
          candidates = board.candidates([row, col])
          if candidates.count == 0
            raise SudokuError.new("Unable to solve board")
          elsif candidates.count == 1
            board.set([row, col], candidates.first)
            solved.push("#{board.friendly_name(row, col)} = #{candidates.first}")
          else
            remaining.push(board.friendly_name(row, col))
          end
        end
      end
    end

    return board, solved, remaining
  end
end

class Board
  def initialize(serialized = nil)
    @values = Array.new(9) { Array.new(9) }

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
  end

  def get(position_name)
    row, col = position_name_to_row_col(position_name)

    get_internal(row, col)
  end

  def candidates(position_name)
    row, col = position_name_to_row_col(position_name)

    candidates_internal(row, col)
  end

  def clear(position_name)
    row, col = position_name_to_row_col(position_name)

    clear_internal(row, col)
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

  # honestly we probably don't need all these "XXX_internal methods, but I like to hide implementations"
  private
  def row_contents(row)
    Set.new(@values[row].compact)
  end

  def col_contents(col)
    Set.new(@values.map {|r| r[col]}.compact)
  end

  def box_contents(row, col)
    row_base = (row / 3).floor * 3
    col_base = (col / 3).floor * 3
    Set.new(@values[row_base..row_base+2].map {|row| row[col_base..col_base+2]}.flatten.compact)
  end

  def set_internal(row, col, value, validate = true)
    @values[row][col] = value
  end
  
  def get_internal(row, col)
    @values[row][col]
  end

  def clear_internal(row, col)
    @values[row][col] = nil
  end

  def candidates_internal(row, col)
    Set.new(1..9) - row_contents(row) - col_contents(col) - box_contents(row, col)
  end

  def box_for_row_col(row_idx, col_idx)
    row_offset = (row_idx / 3).floor * 3
    col_offset = (col_idx / 3).floor

    @boxes[row_offset + col_offset]
  end

  def deserialize(serialized_board)
    chars = serialized_board.split('') # turns it into an 81-character array

    (0..8).each do |row|
      (0..8).each do |col|
        this_val = chars[row * 9 + col]
        this_val = (this_val == '.') ? nil : this_val.to_i

        @values[row][col] = this_val
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