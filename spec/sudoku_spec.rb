require './sudoku'
require 'pry'

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

  context "naked singleton strategy" do
    it "solves an easy puzzle" do
      board = Board.new(easy_solvable_serialized)

      strategy = NakedSingletonStrategy.new
      total_solved = []
      begin
        solved, remaining = board.solve(strategy)
        total_solved += solved
      end while solved.any?

      expect(remaining).to be_empty
      expect(total_solved.sort).to eq([
        "A1 = 5", "A2 = 3", "A4 = 6", "A8 = 2", "B1 = 8", "B2 = 9", "B4 = 3", "B5 = 1", "B6 = 7",
        "B7 = 5", "B8 = 6", "B9 = 4", "C1 = 4", "C2 = 7", "C3 = 6", "C4 = 5", "C6 = 2", "C8 = 3",
        "D1 = 3", "D4 = 7", "D5 = 6", "D8 = 9", "D9 = 8", "E2 = 8", "E5 = 4", "E6 = 9", "E8 = 1",
        "E9 = 5", "F1 = 2", "F2 = 1", "F8 = 7", "F9 = 6", "G1 = 7", "G2 = 5", "G3 = 8", "G5 = 2",
        "G7 = 1", "G8 = 4", "G9 = 3", "H3 = 4", "H4 = 1", "H9 = 2", "J9 = 9"])
    end

    it "improves a hard puzzle" do
      board = Board.new(hard_solvable_serialized)

      strategy = NakedSingletonStrategy.new
      total_solved = []
      begin
        solved, remaining = board.solve(strategy)
        total_solved += solved
      end while solved.any?

      expect(remaining).to_not be_empty
      expect(total_solved.sort).to eq(["E1 = 7", "E2 = 2", "E7 = 5", "E8 = 3"])
    end
  end
end