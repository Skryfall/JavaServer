//
//  SpiderWeb.swift
//  MotorTherapy
//
//  Created by Alejandro Ibarra on 11/1/19.
//  Copyright © 2019 Schlafenhase. All rights reserved.
//

import Foundation

class SpiderWeb {
    
    // MARK: - Attributes
    
    var columns: Int?
    var category = "Category"
    var matrix = [[String]]()
    var path = [[Int]]()
    var midPos = [0, 0]
    var playerPos = [0, 0]
    var rows: Int?
    var scoreMatrix = [[Int]]()
    var tries = 0
    
    // MARK: - Functions
    
    init(_ columns: Int, _ rows: Int, isOnline: Bool) {
        self.columns = columns
        self.rows = rows
        
        if isOnline {
            initializeOnlineAttributes()
        } else {
            initializeOfflineAttributes()
        }
    }
    
    /// Generates path from word collections and inserts it in matrix
    func generatePath() {
        // Obtain random category from collections
        let category = getRandomCategory()
        self.category = category.0
        
        // Start from midPos
        var currentPos = getRandomPos(midPos)
        var onBorder = isOnBorder(midPos)
        var word = ""
        
        // Add words until border is reached
        while !onBorder {
            word = generateRandomWordFromCategory(category.1)
            
            // Insert word in matrix
            matrix[currentPos[0]][currentPos[1]] = word + "P"
            path.append(currentPos)
            
            let nextPos = getRandomPos(currentPos)
            currentPos = nextPos
            onBorder = isOnBorder(nextPos)
        }
        
        // Add end at border
        matrix[currentPos[0]][currentPos[1]] = "END"
        path.append(currentPos)
        
    }
    
    // Gets random category from collections
    func getRandomCategory() -> (String, String) {
        var result = ("0", "0")
        let randNumber = Int.random(in: 0...20)
        switch randNumber {
        case 0:
            result.0 = "3D Graphics"
            result.1 = "3d_graphics"
        case 1:
            result.0 = "Algorithms"
            result.1 = "algorithms"
        case 2:
            result.0 = "Birds"
            result.1 = "birds"
        case 3:
            result.0 = "Cheese"
            result.1 = "cheese"
        case 4:
            result.0 = "Chemistry"
            result.1 = "chemistry"
        case 5:
            result.0 = "Colors"
            result.1 = "colors"
        case 6:
            result.0 = "Design"
            result.1 = "design"
        case 7:
            result.0 = "Devices"
            result.1 = "devices"
        case 8:
            result.0 = "Emotions"
            result.1 = "emotions"
        case 9:
            result.0 = "Filmmaking"
            result.1 = "filmmaking"
        case 10:
            result.0 = "Food"
            result.1 = "food"
        case 11:
            result.0 = "France"
            result.1 = "france"
        case 12:
            result.0 = "Geography"
            result.1 = "geography"
        case 13:
            result.0 = "Hipster"
            result.1 = "hipster"
        case 14:
            result.0 = "Music Production"
            result.1 = "music_production"
        case 15:
            result.0 = "Physics Units"
            result.1 = "physics_units"
        case 16:
            result.0 = "Physics"
            result.1 = "physics"
        case 17:
            result.0 = "Sports"
            result.1 = "sports"
        case 18:
            result.0 = "US Cities"
            result.1 = "united_states"
        case 19:
            result.0 = "Water"
            result.1 = "water"
        case 20:
            result.0 = "Writing"
            result.1 = "writing"
        default:
            result.0 = "Colors"
            result.1 = "colors"
        }
        return result
    }
    
    /// Gets random position from previous position in matrix
    func getRandomPos(_ from: [Int]) -> [Int] {
        let randInt = Int.random(in: 0...3)
        var finalPos = from
        var result: [Int]
        
        switch randInt {
        case 0:
            // Move up
            finalPos[0] -= 1
        case 1:
            // Move down
            finalPos[0] += 1
        case 2:
            // Move left
            finalPos[1] -= 1
        case 3:
            // Move right
            finalPos[1] += 1
        default:
            print("Couldn't get pos")
        }
        
        // Check if result is already on path
        if !path.contains(finalPos) {
            result = finalPos
        } else {
            result = getRandomPos(from)
        }
        
        return result
    }
    
    /// Generate random word from dictionary
    func generateRandomWord() -> String {
        var result: String?
        if let wordsFilePath = Bundle.main.path(forResource: "dictionary", ofType: nil) {
            do {
                let wordsString = try String(contentsOfFile: wordsFilePath)
                let wordLines = wordsString.components(separatedBy: .newlines)
                let randomLine = wordLines[numericCast(arc4random_uniform(numericCast(wordLines.count)))]
                result = randomLine
            } catch {
                // contentsOfFile throws an error
                result = "\(error)"
            }
        }
        return result ?? "Error"
    }
    
    /// Generate random word from category in collection
    func generateRandomWordFromCategory(_ category: String) -> String {
        var result: String?
        if let wordsFilePath = Bundle.main.path(forResource: category, ofType: "txt") {
            do {
                let wordsString = try String(contentsOfFile: wordsFilePath)
                let wordLines = wordsString.components(separatedBy: .newlines)
                let randomLine = wordLines[numericCast(arc4random_uniform(numericCast(wordLines.count)))]
                result = randomLine
            } catch {
                // contentsOfFile throws an error
                result = "\(error)"
            }
        }
        return result ?? "Error"
    }
    
    /// Initializes offline word matrix
    func initializeOfflineMatrix() {
        var currentRow = [String]()
        var currentScoreRow = [Int]()
        let mRows = rows!
        let mColumns = columns!
        
        // Fill matrix with random words
        for _ in 0...(mRows - 1) {
            for _ in 0...(mColumns - 1) {
                // Get random word
                let word = generateRandomWord()
                currentRow.append(word)
                
                // Assign score
                let score = word.count
                currentScoreRow.append(score)
            }
            matrix.append(currentRow)
            scoreMatrix.append(currentScoreRow)
            currentRow.removeAll()
        }
        
        // Search for start/center position in matrix
        midPos[0] = (mRows - 1) / 2
        midPos[1] = (mRows - 1) / 2
        matrix[midPos[0]][midPos[1]] = "START"
    }
    
    /// Initializes online word matrix
    func initializeOnlineMatrix() {
        var currentRow = [String]()
        var currentScoreRow = [Int]()
        let mRows = rows!
        let mColumns = columns!
        
        // Fill matrix with random words
        for _ in 0...(mRows - 1) {
            for _ in 0...(mColumns - 1) {
                // Get random word
                let word = ""
                currentRow.append(word)
                
                // Assign score
                let score = word.count
                currentScoreRow.append(score)
            }
            matrix.append(currentRow)
            scoreMatrix.append(currentScoreRow)
            currentRow.removeAll()
        }
        
        // Search for start/center position in matrix
        midPos[0] = (mRows - 1) / 2
        midPos[1] = (mRows - 1) / 2
        matrix[midPos[0]][midPos[1]] = "START"
    }
    
    /// Initializes attributes if game is online
    func initializeOfflineAttributes() {
        // Initialize default attributes
        initializeOfflineMatrix()
        path.append(midPos)
        generatePath()
        
        // Starting pos is center of matrix
        playerPos[0] = midPos[0]
        playerPos[1] = midPos[1]
        print(matrix)
        print(path)
        print(category)
        print(scoreMatrix)
    }
    
    /// Initializes attributes if game is online
    func initializeOnlineAttributes() {
        // Initialize default attributes
        initializeOnlineMatrix()
        path.append(midPos)
        generatePath()
        
        // Starting pos is center of matrix
        playerPos[0] = midPos[0]
        playerPos[1] = midPos[1]
        print(matrix)
        print(path)
        print(category)
        print(scoreMatrix)
    }
    
    /// Checks if position being tried to add is already on path
    func isOnBorder(_ pos: [Int]) -> Bool {
        var result: Bool
        if pos[0] == 0 || pos[0] == (rows! - 1) || pos[1] == 0 || pos[1] == (columns! - 1) {
            // Check if row or column is 0 or the last one
            result = true
        } else {
            result = false
        }
        return result
    }
    
}
