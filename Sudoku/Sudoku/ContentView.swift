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
    
    let highlights = Array(repeating: Array(repeating: false, count: 9), count: 9)
    
    var body: some View {
        GeometryReader { geometry in
            // Get size of each square
            let boardSize = min(geometry.size.width, geometry.size.height)
            let boxSize = boardSize / CGFloat(sideSize)
            VStack {
                Spacer()
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: sideSize), spacing: 0) {
                    ForEach (0..<sideSize, id: \.self) { col in
                        ForEach (0..<sideSize, id: \.self) { row in
                            let text = grid[col][row] != 0 ? "\(grid[col][row])": " "
                            Button(text) {
                                selectedBox.0 = col
                                selectedBox.1 = row
                            }
                            .frame(width: boxSize, height: boxSize)
                            .contentShape(Rectangle())
                            .font(.system(size: boxSize * 0.6))
                            .foregroundStyle(Color.black)
                            .background(
                                selectedBox.0 == col && selectedBox.1 == row
                                    ? Color.yellow.opacity(0.5)
                                    : selectedBox.0 == col || selectedBox.1 == row
                                        ? Color.yellow.opacity(0.2)
                                        : Color.clear
                            )
                            .overlay(
                                Rectangle()
                                    .stroke(Color.black)
                            )
                        }
                    }
                }
                Spacer()
                Spacer()
            }
        }
        .padding()
    }
}

struct ContentView: View {
    @State private var selectedBox = (0, 0)
    @State private var grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
    
    var body: some View {
        VStack {
            Spacer()
            Board(selectedBox: $selectedBox, grid: $grid)
            Spacer()
            NumberButtons(selectedBox: $selectedBox, grid: $grid)
        }
        
    }
}

#Preview {
    ContentView()
}
