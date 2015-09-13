require './sudoku'

RSpec.describe Board do
  it "set and get work by standard notation" do
    board = Board.new

    board.set("A1", 3)
    value = board.get("A1")
    expect(value).to eq(3)
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
    it "returns all candidates for an empty cell" do
      board = Board.new

      expect(board.candidates("A1")).to eq(Set.new(1..9))
    end

    it "returns a missing candidate if a cell is blocked" do
      board = Board.new

      board.set("C3", 3)
      expect(board.candidates("A1")).to eq(Set.new(1..9) - [3])
    end

    it "returns an empty set if all cells are filled" do
      board = Board.new

      (1..3).each {|i| board.set("A#{i}", i)}
      (4..6).each {|i| board.set("B#{i - 3}", i)}
      (7..9).each {|i| board.set("C#{i - 6}", i)}
      expect(board.candidates("A1")).to eq(Set.new)
    end
  end
end