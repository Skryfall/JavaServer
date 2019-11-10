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
    var wordPath = [[Int]]()
    var midPos = [0, 0]
    var playerPos = [0, 0]
    var rows: Int?
    var scoreMatrix = [[Int]]()
    var tries = 0
    
    // MARK: - Functions
    
    init(_ columns: Int, _ rows: Int, isOnline: Bool) {
        self.columns = columns
        self.rows = rows
        
        // Initialize attributes
        if isOnline {
            initializeOnlineMatrix()
        } else {
            initializeOfflineMatrix()
        }
        
        // Search for start/center position in matrix
        midPos[0] = (rows - 1) / 2
        midPos[1] = (columns - 1) / 2
        matrix[midPos[0]][midPos[1]] = "START"
        wordPath.append(midPos)
        
        // Starting pos is center of matrix
        playerPos[0] = midPos[0]
        playerPos[1] = midPos[1]
        print(matrix)
        print(wordPath)
        print(category)
        print(scoreMatrix)
    }
    
    /// Generate random word from English dictionary
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
    
    /// Gets word in position
    func getWord(_ x: Int,_ y: Int) -> String{
        return matrix[x][y]
    }
    
    /// Initializes offline word matrix
    func initializeOfflineMatrix() {
        // Obtain random category from collections
        let category = getRandomCategory()
        self.category = category.0
        
        var currentRow = [String]()
        var currentScoreRow = [Int]()
        
        // Fill matrix with random words from category
        for i in 0...(rows! - 1) {
            for j in 0...(columns! - 1) {
                // 1 in 7 chance of word being added
                let chance = Int.random(in: 0 ... 7)
                var word = ""
                
                if chance == 7 {
                    // Get random word in category
                    word = generateRandomWordFromCategory(category.1)
                    wordPath.append([i, j])
                }
                currentRow.append(word)
                
                // Assign score
                let score = word.count
                currentScoreRow.append(score)
            }
            matrix.append(currentRow)
            scoreMatrix.append(currentScoreRow)
            currentRow.removeAll()
            currentScoreRow.removeAll()
        }
        
        // Add "END" at random border position
        let randomOrientation = Int.random(in: 0...1)
        var randomX = 0
        var randomY = 0
        if randomOrientation == 0 {
            // Horizontal
            randomX = Int.random(in: 0...(columns! - 1))
            randomY = [0, rows! - 1].randomElement()!
        } else {
            // Vertical
            randomX = Int.random(in: 0...(rows! - 1))
            randomY = [0, columns! - 1].randomElement()!
        }
        matrix[randomX][randomY] = "END"
        scoreMatrix[randomX][randomY] = 0
        wordPath.append([randomX, randomY])
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
            currentScoreRow.removeAll()
        }
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
    
    /// Restarts web in logic
    func restartWeb(isOnline: Bool) {
        matrix.removeAll()
        wordPath.removeAll()
        scoreMatrix.removeAll()
        if isOnline {
            initializeOnlineMatrix()
        } else {
            initializeOfflineMatrix()
        }
    }
    
    /// Gets word in position
    func setWord(_ x: Int,_ y: Int,_ nWord: String){
        matrix[x][y] = nWord
    }
    
}
