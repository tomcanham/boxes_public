require './sudoku'
require 'pry'

include Sudoku

RSpec.describe Board do
  let(:easy_solvable_serialized) do
    "..1.948.7..2..........8.9.1.45..12..6.72..3....98354.....9.6...96..5378.12347865."
  end

  let(:hard_solvable_serialized) do
    "...7.....98....2...76.1..5......3.8...8491..653.....9..9.587.1.8.....6....7..6..."
  end

  it "set and get work by standard notation" do
    board = Board.new

    board.set("A1", 3)
    value = board.get("A1")
    expect(value).to eq(3)
  end

  context "position name mapping" do
    it "works with 'friendly' cell names" do
      expect(Board.new.position_name_to_row_col("J8")).to eq([8,7])
    end

    it "works with pre-mapped [row,col] values" do
      expect(Board.new.position_name_to_row_col([6,3])).to eq([6,3])
    end
  end

  context "duplicates" do 
    it "checks for row duplicates" do
      board = Board.new

      board.set("A1", 3)
      expect { board.set("A2", 3) }.to raise_error(SudokuError)
    end

    it "checks for column duplicates" do
      board = Board.new

      board.set("A1", 3)
      expect { board.set("B1", 3) }.to raise_error(SudokuError)
    end

    it "checks for box duplicates" do
      board = Board.new

      board.set("A1", 3)
      expect { board.set("B2", 3) }.to raise_error(SudokuError)
    end

    it "doesn't register a valid entry as duplicate" do
      board = Board.new

      board.set("A1", 3)
      expect { board.set("B4", 3) }.to_not raise_error
    end
  end

  context "candidates" do
    def filled_box_one
      Board.new('123' + '.' * 6 + '456' + '.' * 6 + '789' + '.' * 60)
    end

    def filled_box_one_except_center
      Board.new('123' + '.' * 6 + '4.6' + '.' * 6 + '789' + '.' * 60)
    end

    it "returns all candidates for an empty cell" do
      board = Board.new

      expect(board.candidates("A1")).to eq(Set.new(1..9))
    end

    it "returns a missing candidate if a cell is blocked" do
      board = Board.new

      board.set("C3", 3)
      expect(board.candidates("A1")).to eq(Set.new(1..9) - [3])
    end

    it "returns the only viable candidate if just one option is available" do
      board = filled_box_one_except_center

      expect(board.candidates("B2")).to eq(Set.new([5]))
    end

    it "returns an empty set if all cells are filled" do
      board = filled_box_one

      expect(board.candidates("A1")).to eq(Set.new)
    end
  end

  context "deserialization" do
    it "works with a fully empty board" do
      board = Board.new('.' * 81)

      expect(board.get("J9")).to be_nil
    end

    it "works with a board with one cell filled" do
      board = Board.new('.' * 40 + '5' + '.' * 40)

      expect(board.get("E5")).to eq(5)
    end

    it "works with an arbitrary solvable board" do
      board = Board.new(easy_solvable_serialized)

      expect(board.get("J4")).to eq(4)
    end
  end

  context "row/col/box singleton strategy" do
    it "solves an easy puzzle" do
      cells = Board.new(easy_solvable_serialized).cell_map

      strategy = Strategies::RowColBoxSingletonStrategy.new

      total_solved = []

      begin
        solved, remaining, cells = strategy.solve(cells)

        total_solved += solved
      end while solved.any?

      expect(remaining).to be_empty
      expect(total_solved.sort).to eq([
        "A1 = 5", "A2 = 3", "A4 = 6", "A8 = 2", "B1 = 8", "B2 = 9", "B4 = 3", "B5 = 1", "B6 = 7",
        "B7 = 5", "B8 = 6", "B9 = 4", "C1 = 4", "C2 = 7", "C3 = 6", "C4 = 5", "C6 = 2", "C8 = 3",
        "D1 = 3", "D4 = 7", "D5 = 6", "D8 = 9", "D9 = 8", "E2 = 8", "E5 = 4", "E6 = 9", "E8 = 1",
        "E9 = 5", "F1 = 2", "F2 = 1", "F8 = 7", "F9 = 6", "G1 = 7", "G2 = 5", "G3 = 8", "G5 = 2",
        "G7 = 1", "G8 = 4", "G9 = 3", "H3 = 4", "H4 = 1", "H9 = 2", "J9 = 9"])
      expect(cells.chain_length).to eq(4) # 4 full iterations required to solve
    end

    it "improves a hard puzzle" do
      cells = Board.new(hard_solvable_serialized).cell_map

      strategy = Strategies::RowColBoxSingletonStrategy.new

      total_solved = []

      begin
        solved, remaining, cells = strategy.solve(cells)

        total_solved += solved
      end while solved.any?

      expect(remaining).to_not be_empty
      expect(total_solved.sort).to eq([
        "C4 = 8", "D2 = 6", "D3 = 9", "D4 = 2", "D5 = 5", "D7 = 7", "E1 = 7", "E2 = 2", "E7 = 5",
        "E8 = 3", "F4 = 6", "F5 = 7", "F6 = 8", "F9 = 2", "G1 = 6", "G3 = 2"])
      expect(cells.chain_length).to eq(4) # 4 full iterations required to give up this strategy
    end
  end

  context "box-line removal strategy" do
    it "correctly removes impossible candidates" do
      cells = Board.new.cell_map

      strategy = Strategies::BoxLineRemovalStrategy.new
      cells.box(0).each { |cell| cell.candidates.delete(1) } # first remove all the "one" candidates
      cells[0][0].candidates.add(1)
      cells[0][1].candidates.add(1) # now A2 & A2 both include 1 as a candidate, and they are the ONLY cells in this box that do

      solved, remaining, cells = strategy.solve(cells) # now, none of the cells in row A should contain the candidate 1 EXCEPT A1 & A2

      expect(remaining).to_not be_empty
      expect(cells[0][3].candidates).to_not include(1)
    end
  end
end