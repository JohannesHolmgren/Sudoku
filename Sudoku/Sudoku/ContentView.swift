//
//  ContentView.swift
//  Sudoku
//
//  Created by Johannes Holmgren on 2025-01-24.
//

import SwiftUI

// ===== Functions for Sudoku logic =====
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
    @State private var grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
    
    var body: some View {
        VStack {
            Spacer()
            Board(selectedBox: $selectedBox, grid: $grid)
            NumberButtons(selectedBox: $selectedBox, grid: $grid)
        }
        
    }
}

#Preview {
    ContentView()
}
