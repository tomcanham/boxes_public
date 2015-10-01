module Sudoku
  class Cell
    attr_reader :map, :row_idx, :col_idx, :ordinal, :candidates
    attr_accessor :value, :row, :col, :box

    def initialize(map, row, col, initial = nil)
      @map = map
      @row_idx = row
      @col_idx = col
      @ordinal = (row * 3) + col
      @candidates = Set.new(1..9)
      value = initial
    end

    def name
      if @name.nil?
        @name = (('A'..'H').to_a+['J'])[@row_idx] + (@col_idx + 1).to_s
      end

      @name
    end

    def copy_state(other_cell)
      @value = other_cell.value
      @candidates = Set.new(other_cell.candidates)
    end

    def empty?
      @value.nil?
    end

    def solved?
      !@value.nil?
    end

    def value=(new_value)
      if new_value
        unless empty?
          raise SudokuError.new("Cell #{name} is already solved")
        end

        unless @candidates.include?(new_value)
          raise SudokuError.new("#{new_value.to_s} is not a valid value for cell #{name}. Valid values are #{@candidates.to_a.join(', ')}.")
        end
      end

      @value = new_value
      map.update_candidates(self)
    end
  end
end