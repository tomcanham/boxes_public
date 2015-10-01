require './board_helper'

# we need this to keep track of candidate counts
module Sudoku
  class CellMap
    include Sudoku::BoardHelper

    attr_reader :previous, :rows, :cols, :boxes

    def initialize(previous = nil)
      reset

      @previous = previous
      init_from(previous) if previous
    end

    def init_from(other)
      (0..8).each do |row|
        (0..8).each do |col|
          @rows[row][col].copy_state(other[row][col])
        end
      end
    end

    def [](row)
      @rows[row]
    end

    def cols(col)
      @cols[col]
    end

    def box(box)
      @boxes[box]
    end

    def update_candidates(cell)
      unless cell.empty?
        affected = cell.row + cell.col + cell.box
        affected.each do |other_cell| 
          other_cell.candidates.delete(cell.value)
        end

        cell.candidates.clear
      end
    end

    def reset(serialized = nil)
      if serialized
        deserialized = deserialize(serialized)
      else
        deserialized = Array.new(81, nil)
      end

      @cells = Array.new(9 * 9) { |idx| Cell.new(self, (idx / 9).floor, idx % 9, deserialized[idx]) }.freeze
      @rows = Array.new(9) { |row| @cells[(row * 9)..((row * 9) + 8)] }.freeze
      @cols = Array.new(9) { |col| @rows.map { |row| row[col] } }.freeze
      @boxes = Array.new(9) do |box_idx|
        start_row = ((box_idx / 3).floor) * 3
        start_col = (box_idx % 3) * 3

        box = []
        (start_row..start_row+2).each do |row|
          (start_col..start_col+2).each do |col|
            box.push(@rows[row][col])
            @rows[row][col].box = box
            @rows[row][col].row = @rows[row]
            @rows[row][col].col = @cols[col]
          end
        end

        box
      end.freeze

      @cells.each { |cell| update_candidates(cell) }
    end

    def chain
      CellMap.new(self)
    end

    def chain_length
      node = self
      count = 0

      while node
        count += 1
        node = node.previous
      end

      count
    end

    def pretty_print
      row_chars = ('A'..'H').to_a+['J']

      puts "\n   " + (1..9).map {|i| " #{i} "}.join
      (0..8).each do |row|
        print " #{row_chars[row]} "
        (0..8).each do |col|
          print " #{@rows[row][col].value || '.'} "
        end
        puts
      end
    end

    def remaining
      @cells.select(&:empty?).compact
    end

    private
    def box_index(row, col)
      (row - (row % 3)) + (col / 3).floor
    end
  end
end