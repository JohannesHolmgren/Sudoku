//
//  ContentView.swift
//  Sudoku
//
//  Created by Johannes Holmgren on 2025-01-24.
//

import SwiftUI

// ===== Functions for Sudoku logic =====
enum SudokuError: Error {
    case missingSet(String)
    case missingRow(Int)
    case invalidBoard
    case invalidDifficulty
}

func isValidSudoku(grid: [[Int]]) -> Bool {
    var colSets = Array(repeating: Set<Int>(), count: 9)
    var subSets = Array(repeating: Set<Int>(), count: 9)
    for row in 0..<9 {
        var rowSet: Set<Int> = []
        for col in 0..<9 {
            let elem = grid[row][col]
            
            // Ignore empty cells
            if elem == 0  {
                continue
            }
            
            // Check row
            if rowSet.contains(elem) {
                return false
            }
            rowSet.insert(elem)
            
            // Check col
            if (colSets[col]).contains(elem) {
                return false
            }
            colSets[col].insert(elem)
            
            // Check 3x3 subgrid
            let subGridIndex = (row / 3) * 3 + (col / 3)
            if subSets[subGridIndex].contains(elem) {
                return false
            }
            subSets[subGridIndex].insert(elem)
            
        }
    }
    return true
}

func generateSudoku(difficulty: String) async -> [[Int]] {
    /* Solve a sudoku board using backtracking */
    
    // Strategy:
    // Diagonal 3x3 boxes are independent
    // => can fill them with numbers 1-9 as we please
    // Then iterate all other positions and fill with random numbers
    // that do not collide
    
    // Map of difficulties
    let difficulties = [
        "easy": 25,
        "medium": 35,
        "hard": 45,
        "difficult": 55
    ]
    
    
    // ----- Step 1: Create a filled in board -----
    // Define sets for each row, col and box
    let rowSets = Array(repeating: Set<Int>(), count: 9)
    let colSets = Array(repeating: Set<Int>(), count: 9)
    let boxSets = Array(repeating: Set<Int>(), count: 9)
    // var sets = ["rows": rowSets, "cols": colSets, "boxes": boxSets]
    
    var sets = (rowSets, colSets, boxSets)
    
    var board = Array(repeating: Array(repeating: 0, count: 9), count: 9)
    createFilledBoard(board: &board, sets: &sets)
    
    // Check if valid
    if !isValidSudoku(grid: board) {
        print("Error: Invalid board")
    }
    
    // ----- Step 2: Remove some numbers from the grid -----
    guard let nToRemove = difficulties[difficulty.lowercased()] else {print("Error: could not load difficulty"); return board}
    removeRandomNumbers(from: &board, n: nToRemove, sets: &sets)
    
    
    return board
}

func removeRandomNumbers(from board: inout [[Int]], n: Int, sets: inout ([Set<Int>], [Set<Int>], [Set<Int>])) {
    var allPositions: [(Int, Int)] = []
    for i in 0..<9 {
        for j in 0..<9 {
            allPositions.append((i, j))
        }
    }

    let _ = removeNumbers(from: &board, n: n, allPositions: allPositions.shuffled(), sets: &sets)
    
}

func removeNumbers(from board: inout [[Int]], n: Int, allPositions: [(Int, Int)], sets: inout ([Set<Int>], [Set<Int>], [Set<Int>])) -> Bool {
    if n == 0 {
        // print("Success")
        return true
    }
    var positions = allPositions
    var removedPositions: [(Int, Int)] = []
    while true {
        guard let pos = positions.popLast() else {
            // print("No more possibilities")
            return false
        }
        removedPositions.append(pos)
        // Check if has unique solution when this is removed
        let saved = board[pos.0][pos.1]
        removeNumberFromBoard(num: saved, pos: pos, board: &board, sets: &sets)
        // print("\(n): Size of removed positions: \(removedPositions.count)")
        
        board[pos.0][pos.1] = 0
        if hasUniqueSolution(board: board, removedPositions: removedPositions, sets: &sets) {
            // print("\(n): Unique solution for \(pos). positions size: \(positions.count)")
            if removeNumbers(from: &board, n: n - 1, allPositions: positions, sets: &sets) {
                // print("Removed number at \(pos)")
                return true
            }
        }
        // Reset board
        addNumberToBoard(num: saved, pos: pos, board: &board, sets: &sets)
        _ = removedPositions.popLast()
        
        
    }
    return false
}

func hasUniqueSolution(board: [[Int]], removedPositions: [(Int, Int)], sets: inout ([Set<Int>], [Set<Int>], [Set<Int>])) -> Bool {
    return countNumberofSolutions(board: board, remainingPositions: removedPositions, sets: &sets) == 1
}

/* Check if board has a unique solution */
func countNumberofSolutions(board: [[Int]], remainingPositions: [(Int, Int)], sets: inout ([Set<Int>], [Set<Int>], [Set<Int>])) -> Int {
    // Try to solve board from here and return number of solutions
    var newBoard = board
    var positions = remainingPositions
    guard let (i, j) = positions.popLast() else { return 1 }
    
    var nSolutions = 0
    let digits = (1...9).shuffled()
    for num in digits {
        if isValidDigit(board: board, pos: (i, j), num: num, sets: &sets) {
            newBoard[i][j] = num
            // Update all sets to say that the digit is here
            addNumberToBoard(num: num, pos: (i, j), board: &newBoard, sets: &sets)
            
            // Count number of solutions from here
            nSolutions += countNumberofSolutions(board: newBoard, remainingPositions: positions, sets: &sets)
            if nSolutions > 1 {
                return nSolutions
            }
            
            // Try next number
            removeNumberFromBoard(num: num, pos: (i, j), board: &newBoard, sets: &sets)
        }
    }
    
    return nSolutions
    
}


func createFilledBoard(board: inout [[Int]], sets: inout ([Set<Int>], [Set<Int>], [Set<Int>]) ) { // Dictionary<String, [Set<Int>]>) {
    // 1. Fill diagonal 3x3 with random numbers 1-9
    initializeDiagonalBoxes(board: &board, sets: &sets)
    
    // 2. Get all remaining positions (those that are not in the diagonals
    let remainingPositions = getRemainingPositions().shuffled()
    
    // 3. Fill remaining boxes to complete a valid sudoku
    let _ = fillSudoku(board: &board, remainingPositions: remainingPositions, sets: &sets)
    
    // Check if valid sudoku
    
    // ...
    
}

func initializeDiagonalBoxes(board: inout [[Int]], sets: inout ([Set<Int>], [Set<Int>], [Set<Int>])) {
    // Create empty sudoku board
    // All 3 diagonal boxes are indpendent from each other. Start with placing
    // 1-9 randomly in each of these boxes
    
    for diagIndex in 0..<3 {
        var digits = (1..<10).shuffled()
        for i in 0..<3 {
            for j in 0..<3 {
                // Fill board
                let rowIndex = i + diagIndex * 3
                let colIndex = j + diagIndex * 3
                let digit = digits.popLast() ?? 0
                addNumberToBoard(num: digit, pos: (rowIndex, colIndex), board: &board, sets: &sets)
            }
        }
    }
}


/* Get all positions that are not in the 3 diagonal boxes. */
func getRemainingPositions() -> [(Int, Int)] {
    var remainingPositions: [(Int, Int)] = []
    
    // Upper
    for i in 3..<9 {
        for j in 0..<3 {
            let pos = (i, j)
            remainingPositions.append(pos)
        }
    }
    // Middle
    for i in Array(0..<3) + Array(6..<9) {
        for j in 3..<6 {
            let pos = (i, j)
            remainingPositions.append(pos)
        }
    }
    // Lower
    for i in 0..<6 {
        for j in 6..<9 {
            let pos = (i, j)
            remainingPositions.append(pos)
        }
    }
    
    return remainingPositions
}


func fillSudoku(board: inout [[Int]], remainingPositions: [(Int, Int)], sets: inout ([Set<Int>], [Set<Int>], [Set<Int>])) -> Bool {
    var positions = remainingPositions
    guard let (i, j) = positions.popLast() else { return true }
    
    let digits = (1..<10).shuffled()
    for num in digits {
        if isValidDigit(board: board, pos: (i, j), num: num, sets: &sets) {
            board[i][j] = num
            // Update all sets to say that the digit is here
            addNumberToBoard(num: num, pos: (i, j), board: &board, sets: &sets)
            
            if fillSudoku(board: &board, remainingPositions: positions, sets: &sets) {
                return true
            }
            // Did not work from here. Reset board
            removeNumberFromBoard(num: num, pos: (i, j), board: &board, sets: &sets)
        }
    }
    return false
    
}
 

func isValidDigit(board: [[Int]], pos: (Int, Int), num: Int, sets: inout ([Set<Int>], [Set<Int>], [Set<Int>])) -> Bool {
    let (rowIndex, colIndex) = pos
    let boxIndex = Int(floor(Double(rowIndex / 3)) + floor(Double(colIndex / 3)) * 3)
    
    // Check row
    if (sets.0)[rowIndex].contains(num) {
        return false
    }
    // Check col
    if (sets.1)[colIndex].contains(num) {
        return false
    }
    // Check box
    if (sets.2)[boxIndex].contains(num) {
        return false
    }
    
    return true
}

func addNumberToBoard(num: Int, pos: (Int, Int), board: inout [[Int]], sets: inout ([Set<Int>], [Set<Int>], [Set<Int>])) {
    // Get indices
    let (rowIndex, colIndex) = pos
    let boxIndex = Int(floor(Double(rowIndex / 3)) + floor(Double(colIndex / 3)) * 3)
    
    // Update board
    board[rowIndex][colIndex] = num
    
    // Update sets
    (sets.0)[rowIndex].insert(num)
    (sets.1)[colIndex].insert(num)
    (sets.2)[boxIndex].insert(num)
}

func removeNumberFromBoard(num: Int, pos: (Int, Int), board: inout [[Int]], sets: inout ([Set<Int>], [Set<Int>], [Set<Int>])) {
    // Get indices
    let (rowIndex, colIndex) = pos
    let boxIndex = Int(floor(Double(rowIndex / 3)) + floor(Double(colIndex / 3)) * 3)
    
    // Update board
    board[rowIndex][colIndex] = 0
    
    // Update sets
    (sets.0)[rowIndex].remove(num)
    (sets.1)[colIndex].remove(num)
    (sets.2)[boxIndex].remove(num)
}


struct NumberButtons: View {
    @Binding var selectedBox: (Int, Int)
    @Binding var grid: [[Int]]
    
    @State private var selectedNumber: Int? = nil
    
    // Callback for when pressing a number
    func fillNumber(num: Int) {
        grid[selectedBox.0][selectedBox.1] = num
    }
    
    var body: some View {
        HStack {
            ForEach (1..<10) { num in
                NumberButton(number: num, onPress: fillNumber)
            }
        }
    }
}

struct NumberButton: View {
    let number: Int
    var onPress: (Int) -> Void
    
    var body: some View {
        Button("\(number)") {
            onPress(number)
        }
        .font(.system(size: 32))
        .fontWeight(Font.Weight.medium)
        .padding(7)
        .foregroundStyle(Color.black)
    }
}


struct Board: View {
    @Binding var selectedBox: (Int, Int)
    @Binding var grid: [[Int]]
    
    let sideSize = 9
    
    @State private var highlights = Array(repeating: Array(repeating: false, count: 9), count: 9)
    
    // Used to update selected box
    func setSelected(row: Int, col: Int) -> Void {
        selectedBox.0 = row
        selectedBox.1 = col
    }
    
    var body: some View {
        GeometryReader { geometry in
            // Get size of each square
            let boardSize = min(geometry.size.width, geometry.size.height)
            let boxSize = boardSize / CGFloat(sideSize)
            VStack {
                Spacer()
                ZStack {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: sideSize), spacing: 0) {
                        ForEach (0..<sideSize, id: \.self) { row in
                            ForEach (0..<sideSize, id: \.self) { col in
                                NumberBox(row: row, col: col, content: grid[row][col], boxSize: boxSize, selectedBox: $selectedBox, onPress: self.setSelected)
                            }
                            
                        }
                    }
                    // Bold lines between each 3x3 box
                    Separators(boxSize: boxSize, boardSize: boardSize)
                    
                }
                Spacer()
                Spacer()
            }
        }
        .padding()
    }
}

struct NumberBox: View {
    let row: Int
    let col: Int
    let content: Int
    let boxSize: CGFloat
    @Binding var selectedBox: (Int, Int)
    var onPress: (Int, Int) -> Void
    
    let highlightColor = Color.yellow
    
    // Setup border logic
    
    
    var body: some View {
        // Set box to be empty if not nubmers 1-9
        let text = content != 0 ? "\(content)": " "
        Button(text) {
            onPress(row, col)
        }
        .frame(width: boxSize, height: boxSize)
        .contentShape(Rectangle())
        .font(.system(size: boxSize * 0.8))
        .foregroundStyle(Color.black)
        .background(
            selectedBox.0 == row && selectedBox.1 == col
                ? highlightColor.opacity(0.5)
                : selectedBox.0 == row || selectedBox.1 == col
                    ? highlightColor.opacity(0.2)
                    : Color.clear
        )
        .overlay(
            Rectangle()
                .stroke(Color.black.opacity(0.2))
        )
    }
    
}

struct Separators: View {
    let boxSize: CGFloat
    let boardSize: CGFloat
    let borderWidth: CGFloat = 2
    
    var body: some View {
        // Vertical bold lines
        Rectangle()
            .frame(width: borderWidth, height: boardSize)
            .foregroundColor(Color.black)
            .offset(x: boxSize * -4.5)
        Rectangle()
            .frame(width: borderWidth, height: boardSize)
            .foregroundColor(Color.black)
            .offset(x: boxSize * -1.5)
        Rectangle()
            .frame(width: borderWidth, height: boardSize)
            .foregroundColor(Color.black)
            .offset(x: boxSize * 1.5)
        Rectangle()
            .frame(width: borderWidth, height: boardSize)
            .foregroundColor(Color.black)
            .offset(x: boxSize * 4.5)
        // Horizontal bold lines
        Rectangle()
            .frame(width: boardSize, height: borderWidth)
            .foregroundColor(Color.black)
            .offset(y: boxSize * -4.5)
        Rectangle()
            .frame(width: boardSize, height: borderWidth)
            .foregroundColor(Color.black)
            .offset(y: boxSize * -1.5)
        Rectangle()
            .frame(width: boardSize, height: borderWidth)
            .foregroundColor(Color.black)
            .offset(y: boxSize * 1.5)
        Rectangle()
            .frame(width: boardSize, height: borderWidth)
            .foregroundColor(Color.black)
            .offset(y: boxSize * 4.5)
    }
}

struct ContentView: View {
    @State private var selectedBox = (0, 0)
    @State private var grid =  Array(repeating: Array(repeating: 0, count: 9), count: 9)
    @State private var isLoading = false
    @State private var difficulty = "easy"
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Generating Sudoku...")
            } else {
                VStack {
                    Spacer()
                    Board(selectedBox: $selectedBox, grid: $grid)
                    NumberButtons(selectedBox: $selectedBox, grid: $grid)
                }
            }
        }
        .padding()
        .task {
            await generateNewSudoku()
        }
    }
    
    func generateNewSudoku() async {
        isLoading = true
        grid = await generateSudoku(difficulty: difficulty)
        isLoading = false
    }
}


#Preview {
    ContentView()
}
