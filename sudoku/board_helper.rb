module Sudoku
  module BoardHelper
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
      serialized_board.split('').map { |c| c == '.' ? nil : c.to_i }
    end

    def set(position_name, value)
      row, col = position_name_to_row_col(position_name)

      @cell_map[row][col].value = value
    end

    def get(position_name)
      row, col = position_name_to_row_col(position_name)

      @cell_map[row][col].value
    end
  end
end