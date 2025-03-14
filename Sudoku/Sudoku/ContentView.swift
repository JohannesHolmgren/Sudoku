//
//  ContentView.swift
//  Sudoku
//
//  Created by Johannes Holmgren on 2025-01-24.
//

import SwiftUI


struct Game {
    var board: [[Int]] = Array(repeating: Array(repeating: 0, count: 9), count: 9)
    var solution: [[Int]] = Array(repeating: Array(repeating: 0, count: 9), count: 9)
    var selected : (Int, Int) = (0, 0)
    
    mutating func resetBoard() -> Void {
        self.board = Array(repeating: Array(repeating: 0, count: 9), count: 9)
    }
    
    func hasWon() -> Bool {
        return true
        // return isFull() && isValidSudoku(grid: board)
    }
    
    func isFull() -> Bool {
        for row in 0..<9 {
            for col in 0..<9 {
                if board[row][col] == 0 {
                    return false
                }
            }
        }
        return true
    }
}


struct NumberButtons: View {
    @Binding var game: Game
    // @Binding var selectedBox: (Int, Int)
    // @Binding var grid: [[Int]]
    
    @State private var selectedNumber: Int? = nil
    
    // Callback for when pressing a number
    func fillNumber(num: Int) {
        game.board[game.selected.0][game.selected.1] = num
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
        .font(.system(size: 42))
        .fontWeight(Font.Weight.medium)
        .padding(5)
        .foregroundStyle(Color.black)
    }
}


struct Board: View {
    @Binding var game: Game
//    var selectedBox = game.selected
//    var grid = game.board
    
    let sideSize = 9
    
    @State private var highlights = Array(repeating: Array(repeating: false, count: 9), count: 9)
    
    // Used to update selected box
    func setSelected(row: Int, col: Int) -> Void {
        game.selected.0 = row
        game.selected.1 = col
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
                                NumberBox(row: row, col: col, content: game.board[row][col], boxSize: boxSize, game: $game, onPress: self.setSelected)
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
        // .padding()
    }
}

struct NumberBox: View {
    let row: Int
    let col: Int
    let content: Int
    let boxSize: CGFloat
    @Binding var game: Game
    // @Binding var selectedBox: (Int, Int)
    var onPress: (Int, Int) -> Void
    
    let highlightColor = Color.red
    
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
            game.selected.0 == row && game.selected.1 == col
                ? highlightColor.opacity(0.5)
            : game.selected.0 == row || game.selected.1 == col
                ? highlightColor.opacity(0.2)
            : game.board[game.selected.0][game.selected.1] == game.board[row][col] && game.board[row][col] != 0
                ? highlightColor.opacity(0.4)
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
        
        ForEach (0..<4) { i in
            // Vertical bold lines
            Rectangle()
                .frame(width: borderWidth, height: boardSize)
                .foregroundColor(Color.black)
                .offset(x: boxSize * (-4.5 + CGFloat(i * 3)))
            // Horizontal bold lines
            Rectangle()
                .frame(width: boardSize, height: borderWidth)
                .foregroundColor(Color.black)
                .offset(y: boxSize * (-4.5 + CGFloat(i * 3)))
        }
    }
}

struct StartPage: View {
    let startPlaying: (String) -> Void
    let difficulties = ["Easy", "Medium", "Hard", "Harder"]
    
    var body: some View {
        Spacer()
        Text("Sudoku App")
            .font(.largeTitle)
        Spacer()
        Spacer()
        VStack {
            VStack {
                ForEach (difficulties, id: \.self) { difficulty in
                    Button(action:  {
                        startPlaying(difficulty)
                    }) {
                        Text(difficulty)
                            .foregroundStyle(.white)
                            .font(.headline)
                            .fontWeight(.bold)
                            .frame(width: 200, height: 55)
                            .background(Color.blue)
                            .cornerRadius(60)
                    }
                }
            }
        }
        Spacer()
    }
}

struct BoardPage: View {
    let stopPlaying: () -> Void
    let difficulty: String
    @State private var isLoading = true
    @State private var game = Game()
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Generating Sudoku...")
            } else if game.hasWon() {
                VStack {
                    Text("You Won!!!")
                    Button(action: {
                        game.resetBoard()
                        stopPlaying()
                    }) {
                        Text("Back to Start")
                    }
                }
            } else {
                VStack {
                    Spacer()
                    Board(game: $game)
                    NumberButtons(game: $game)
                }
            }
        }
        .padding()
        .task {
            await generateNewSudoku(difficulty: difficulty)
        }
    }
    
    func generateNewSudoku(difficulty: String) async {
        isLoading = true
        let (grid, solution) = await generateSudoku(difficulty: difficulty)
        game.board = grid
        game.solution = solution
        isLoading = false
    }

}

struct ContentView: View {
    @State private var isPlaying = false
    @State private var difficulty = "easy"
    
    var body: some View {
        if isPlaying {
            BoardPage(stopPlaying: stopPlaying, difficulty: difficulty)
        } else {
            StartPage(startPlaying: startPlaying)
        }
    }
    
    func startPlaying(level: String) {
        isPlaying = true
        difficulty = level
    }
    
    func stopPlaying() {
        isPlaying = false
    }
}


#Preview {
    ContentView()
}
