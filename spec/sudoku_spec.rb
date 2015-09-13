require './sudoku'

RSpec.describe Board do
  let(:solvable_serialized) do
    "..1.948.7..2..........8.9.1.45..12..6.72..3....98354.....9.6...96..5378.12347865."
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
      board = Board.new

      (1..3).each {|i| board.set("A#{i}", i)}
      (4..6).each {|i| board.set("B#{i - 3}", i)}
      (7..9).each {|i| board.set("C#{i - 6}", i)}

      board
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
      board = filled_box_one

      board.clear("B2") # clear the "5" cell
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
      board = Board.new(solvable_serialized)

      expect(board.get("J4")).to eq(4)
    end
  end
end