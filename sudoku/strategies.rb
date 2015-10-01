require 'set'

module Sudoku
  module Strategies
    class NakedSingletonStrategy
      def solve(cell_map)
        solved = []
        remaining = []
        cells = cell_map.chain

        (0..8).each do |row|
          (0..8).each do |col|
            cell = cells[row][col]

            unless cell.solved?
              candidates = cell.candidates
              if candidates.count == 1
                cell.value = candidates.first
                solved.push("#{cell.name} = #{cell.value}")
              end
            end
          end
        end

        return solved, cells.remaining, cells
      end
    end

    class RowColBoxSingletonStrategy
      def solve(cell_map)
        solved = []
        cells = cell_map.chain

        (0..8).each do |index|
          (1..9).each do |candidate_value|
            row = cells[index]
            col = cells.cols(index)
            box = cells.box(index)

            [row, col, box].each do |unit|
              cells_with_candidate = unit.select {|cell| cell.empty? && cell.candidates.include?(candidate_value)}
              if cells_with_candidate.count == 1
                solvable_cell = cells_with_candidate.first

                # only one cell in this row/col/box has this value as a candidate. It MUST be the correct cell!
                # note that this also catches "naked" singletons (cases where only one choice is possible) as the
                # degenerate case of the general strategy.
                solvable_cell.value = candidate_value # this will cascade to other cells
                solved.push("#{solvable_cell.name} = #{solvable_cell.value}")
              end
            end
          end
        end

        return solved, cells.remaining, cells
      end
    end

    class BoxLineRemovalStrategy
      def eliminate_candidates(first, second, unit, candidate)
        cells_with_candidate = [first, second]
        cells_to_alter = unit.select do |cell| 
          cell.empty? &&
          cell.candidates.include?(candidate) &&
          !cells_with_candidate.include?(cell)
        end
        cells_to_alter.each { |cell| cell.candidates.delete(candidate) }

        puts "Deleted #{cells_to_alter.count} candidate(s) with value #{candidate}"
        cells_to_alter.count # return how many candidates were deleted
      end

      def solve(cell_map)
        solved = []
        cells = cell_map.chain

        cells.boxes.each do |box|
          (1..9).each do |candidate_value|
            cells_with_candidate = box.select {|cell| cell.empty? && cell.candidates.include?(candidate_value)}
            if cells_with_candidate.count == 2
              first, second = cells_with_candidate
              if first.row == second.row
                eliminate_candidates(first, second, first.row, candidate_value)
              elsif first.col == second.col
                eliminate_candidates(first, second, first.col, candidate_value)
              end                
            end
          end
        end

        return solved, cells.remaining, cells
      end
    end
  end
end