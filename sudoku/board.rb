module Sudoku
  class SudokuError < RuntimeError
  end

  class Board
    attr_reader :cell_map

    def initialize(serialized = nil)
      @cell_map = CellMap.new

      unless serialized.nil?
        deserialize(serialized)
      end    
    end

    def set(position_name, value)
      row, col = position_name_to_row_col(position_name)

      @cell_map[row][col].value = value
    end

    def get(position_name)
      row, col = position_name_to_row_col(position_name)

      @cell_map[row][col].value
    end

    def candidates(position_name)
      row, col = position_name_to_row_col(position_name)

      @cell_map[row][col].candidates
    end

    def position_name_to_row_col(position_name)
      if position_name.instance_of?(Array)
        return position_name[0], position_name[1]
      else
        row_name = position_name[0].upcase
        col_name = position_name[1]

        row_idx = (('A'..'H').to_a+['J']).index(row_name)
        col_idx = col_name.to_i - 1

        return row_idx, col_idx
      end
    end

    def deserialize(serialized_board)
      chars = serialized_board.split('') # turns it into an 81-character array

      @cell_map.reset
      (0..8).each do |row|
        (0..8).each do |col|
          this_val = chars[row * 9 + col]
          this_val = (this_val == '.') ? nil : this_val.to_i

          @cell_map[row][col].value = this_val
        end
      end
    end
  end
end