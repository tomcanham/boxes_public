require 'set'

class SudokuError < RuntimeError
end

class Board
  def initialize
    @values = Array.new(9) { Array.new(9) }
  end

  def set(position_name, value)
    row, col = position_name_to_row_col(position_name)
    canonical_name = position_name.upcase

    unless get_internal(row, col).nil?
      raise SudokuError.new("Cell #{canonical_name} is already solved")
    end

    unless candidates(position_name).include?(value)
      raise SudokuError.new("#{value.to_s} is not a valid value for cell #{canonical_name}. Valid values are #{candidates(position_name).to_a.join(', ')}.")
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

  def set_internal(row, col, value)
    @values[row][col] = value
  end
  
  def get_internal(row, col)
    @values[row][col]
  end

  def candidates_internal(row, col)
    Set.new(1..9) - row_contents(row) - col_contents(col) - box_contents(row, col)
  end

  def position_name_to_row_col(position_name)
    row_name = position_name[0].upcase
    col_name = position_name[1]

    row_idx = (('A'..'H').to_a+['J']).index(row_name)
    col_idx = col_name.to_i - 1

    return row_idx, col_idx
  end

  def box_for_row_col(row_idx, col_idx)
    row_offset = (row_idx / 3).floor * 3
    col_offset = (col_idx / 3).floor

    @boxes[row_offset + col_offset]
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