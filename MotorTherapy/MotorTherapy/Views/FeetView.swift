//
//  FeetView.swift
//  MotorTherapy
//
//  Created by Alejandro Ibarra on 10/29/19.
//  Copyright © 2019 Schlafenhase. All rights reserved.
//

import ARKit
import AVFoundation
import Combine
import RealityKit
import UIKit

class FeetView: UIViewController, ARSessionDelegate {
    
    // MARK: - UI Elements
    
    // Main UI views
    @IBOutlet var arView: ARView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var controlView: UIView!
    @IBOutlet weak var queueView: UIView!
    
    // Buttons and other elements
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var endGameLabel: UILabel!
    @IBOutlet weak var messageLabel: MessageLabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var timerLabel: UILabel!
    
    // Queue views
    @IBOutlet weak var queueColor1: UIImageView!
    @IBOutlet weak var queueColor2: UIImageView!
    @IBOutlet weak var queueColor3: UIImageView!
    @IBOutlet weak var queueColor4: UIImageView!
    
    // TEMP TEST BUTTONS
    @IBOutlet weak var blueButton: UIButton!
    @IBOutlet weak var brownButton: UIButton!
    @IBOutlet weak var cyanButton: UIButton!
    @IBOutlet weak var greenButton: UIButton!
    @IBOutlet weak var greyButton: UIButton!
    @IBOutlet weak var orangeButton: UIButton!
    @IBOutlet weak var magentaButton: UIButton!
    @IBOutlet weak var purpleButton: UIButton!
    @IBOutlet weak var redButton: UIButton!
    @IBOutlet weak var yellowButton: UIButton!
    
    @IBAction func blueTap(_ sender: Any) {
        signalBall("blue")
    }
    @IBAction func brownTap(_ sender: Any) {
        signalBall("brown")
    }
    @IBAction func cyanTap(_ sender: Any) {
        signalBall("cyan")
    }
    @IBAction func greenTap(_ sender: Any) {
        signalBall("green")
    }
    @IBAction func greyTap(_ sender: Any) {
        signalBall("grey")
    }
    @IBAction func orangeTap(_ sender: Any) {
        signalBall("orange")
    }
    @IBAction func magentaTap(_ sender: Any) {
        signalBall("magenta")
    }
    @IBAction func purpleTap(_ sender: Any) {
        signalBall("purple")
    }
    @IBAction func redTap(_ sender: Any) {
        signalBall("red")
    }
    @IBAction func yellowTap(_ sender: Any) {
        signalBall("yellow")
    }
    
    // MARK: - Attributes
    
    // Constants
    let gameName = "Feet"
    
    // Entity data
    var bodyAnchorExists = false
    var bodyPosition: simd_float3?
    var character: BodyTrackedEntity?
    let characterAnchor = AnchorEntity()
    var leftBox = Entity()
    var leftBoxUp = Entity()
    var rightBox = Entity()
    var rightBoxUp = Entity()
    
    // Color balls
    var blueBall = Entity()
    var brownBall = Entity()
    var cyanBall = Entity()
    var greenBall = Entity()
    var greyBall = Entity()
    var orangeBall = Entity()
    var redBall = Entity()
    var magentaBall = Entity()
    var purpleBall = Entity()
    var yellowBall = Entity()
    
    // Queue, timer and point management data
    var allColorQueueList = [[String]]()
    var allScoreList = [[Int]]()
    var allTimeList = [[Int]]()
    var currentColorQueueList = [String]()
    var currentScoreList = [Int]()
    var currentTimeList = [Int]()
    var rounds = 0
    var score = 0
    var seconds = 0
    var timer = Timer()
    var totalScore = 0
    
    // Additional variables for control
    var audioPlayer = AVAudioPlayer()
    var holder = Holder()
    var isFirstTime = true
    var isOnline: Bool?
    var isOver = false
    var passPlayer = AVAudioPlayer()
    var tickPlayer = AVAudioPlayer()
    
    // Offline posibilities for variables
    let possibleColors = ["blue", "brown", "cyan", "green", "grey", "orange", "magenta", "purple", "red", "yellow"]
    let possibleTimes = [6, 7, 8, 9, 10]
    let possibleRounds = [3, 4, 5]
    let possibleRoundsInRound = [5, 7, 8]
    let possibleScores = 3...15
    
    // Reality Composer scene
    var experienceScene = Experience.Scene()
    
    // Flush Collision events list for memory management
    var collisionEventStreams = [AnyCancellable]()
    deinit {
        collisionEventStreams.removeAll()
        endGame()
    }
    
    // MARK: - Functions
    
    /// Animates queue entrance when start
    func animateQueueIntro() {
        queueView.isHidden = false
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       options: .curveEaseOut,
                       animations: {
                        self.queueView.frame.origin.x -= 290
                        })
    }
    
    /// Animates queue entrance when end
    func animateQueueOutro() {
        queueView.isHidden = false
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       options: .curveEaseOut,
                       animations: {
                        self.queueView.frame.origin.x += 290
                        })
    }
    
    /// Enables  or disables UI elements while connecting
    func disableUI(_ block: Bool) {
        if block {
            backButton.isEnabled = false
            startButton.isEnabled = false
        } else {
            backButton.isEnabled = true
            startButton.isEnabled = true
        }
    }
    
    /// Draws color in flag queue view
    func drawQueue() {
        let color1: String?
        let color2: String?
        let color3: String?
        let color4: String?
        let colorCount = currentColorQueueList.count
        
        if colorCount > 3 {
            // All colors to be showed
            color1 = currentColorQueueList[0]
            color2 = currentColorQueueList[1]
            color3 = currentColorQueueList[2]
            color4 = currentColorQueueList[3]
            queueColor1.backgroundColor = getColor(color: color1!)
            queueColor2.backgroundColor = getColor(color: color2!)
            queueColor3.backgroundColor = getColor(color: color3!)
            queueColor4.backgroundColor = getColor(color: color4!)
        } else if colorCount == 3 {
            // Only 3 colors to be showed
            color1 = currentColorQueueList[0]
            color2 = currentColorQueueList[1]
            color3 = currentColorQueueList[2]
            queueColor1.backgroundColor = getColor(color: color1!)
            queueColor2.backgroundColor = getColor(color: color2!)
            queueColor3.backgroundColor = getColor(color: color3!)
            queueColor4.backgroundColor = .clear
        } else if colorCount == 2 {
            // Only 2 colors to be showed
            color1 = currentColorQueueList[0]
            color2 = currentColorQueueList[1]
            queueColor1.backgroundColor = getColor(color: color1!)
            queueColor2.backgroundColor = getColor(color: color2!)
            queueColor3.backgroundColor = .clear
            queueColor4.backgroundColor = .clear
        } else if colorCount == 1 {
            // Only 1 color to be showed
            color1 = currentColorQueueList[0]
            queueColor1.backgroundColor = getColor(color: color1!)
            queueColor2.backgroundColor = .clear
            queueColor3.backgroundColor = .clear
            queueColor4.backgroundColor = .clear
        }
    }
    
    /// Ends game
    func endGame() {
        timer.invalidate()
        showWinScreen()
        score = 0
    }
    
    /// Gets color from string
    func getColor(color: String) -> UIColor {
        var result: UIColor
        switch color {
        case "blue":
            result = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
        case "green":
            result = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
        case "red":
            result = #colorLiteral(red: 1, green: 0, blue: 0.2711882889, alpha: 1)
        case "orange":
            result = #colorLiteral(red: 1, green: 0.4839532375, blue: 0.1407360137, alpha: 1)
        case "yellow":
            result = #colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 1)
        case "brown":
            result = #colorLiteral(red: 0.5608243942, green: 0.3643547297, blue: 0.04435489327, alpha: 1)
        case "purple":
            result = #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1)
        case "grey":
            result = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
        case "magenta":
            result = #colorLiteral(red: 1, green: 0.3899285197, blue: 0.6967676282, alpha: 1)
        case "cyan":
            result = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        default:
            result = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        }
        return result
    }
    
    /// Loads objects in scene
    func loadObjects() {
        loadReality()
        loadRobot()
        loadTickSound()
        loadPassSound()
    }
    
    /// Initializes attributes from local random generation
    func initializeOfflineAttributes() {
        messageLabel.text = "Loading..."
        
        // Randomize color, score and time
        rounds = possibleRounds.randomElement()!
        var colorList = [String]()
        var scoreList = [Int]()
        var timeList = [Int]()
        
        for _ in 1...rounds {
            // Randomize number of rounds within each round
            let roundsinRound = possibleRoundsInRound.randomElement()!
            
            for _ in 1...roundsinRound {
                // Randomize elements in sub-list of random elements
                let randomColor = possibleColors.randomElement()!
                let randomScore = possibleScores.randomElement()!
                let randomTime = possibleTimes.randomElement()!
                
                colorList.append(randomColor)
                scoreList.append(randomScore)
                timeList.append(randomTime)
                totalScore += randomScore
            }
            
            // Add new sub-list to global list of elements
            allColorQueueList.append(colorList)
            allScoreList.append(scoreList)
            allTimeList.append(timeList)
            
            // Clear lists for next iteration
            colorList.removeAll()
            scoreList.removeAll()
            timeList.removeAll()
        }
        messageLabel.displayMessage("Loaded", duration: 3, gameName)
    }
    
    /// Initializes attributes from server
    func initializeOnlineAttributes() {
        // Connect to server to update holder
        messageLabel.text = "Connecting..."
        disableUI(true)
        
        do {
            holder = connectToServer()
            if !holder.connectionSuccess! {
                // Error connecting. Redirect to offline mode
                redirectToOfflineMode()
            } else {
                // Connection to server success
                let colorInstructions = holder.flagColorsInstructions
                let scoreInstructions = holder.flagPointsInstructions
                let timeInstructions = holder.flagTimeInstructions
                let roundCount: Int?
                
                if colorInstructions?.count != scoreInstructions?.count {
                    // Error. Round data doesn't match convention
                    redirectToOfflineMode()
                } else {
                    // Sort incoming list data
                    roundCount = colorInstructions?.count
                    
                    for i in 0...(roundCount! - 1) {
                        let currentColorInstruction = colorInstructions![i]
                        let currentScoreInstruction = scoreInstructions![i]
                        let currentTimeInstruction = timeInstructions!
                        
                        var currentColorList = [String]()
                        var currentNScoreList = [Int]()
                        var currentTimeList = [Int]()
                        
                        // Divide session time equally for each ball
                        let sessionTime = currentTimeInstruction[i]
                        let ballTime = sessionTime / currentColorInstruction.count
                        
                        if currentColorInstruction.count != currentScoreInstruction.count {
                            // Error. Round in round count doesn't match convention
                            redirectToOfflineMode()
                            break
                        } else {
                            let roundsInRound = currentColorInstruction.count
                            var breakVar = false
                            
                            // Sort colors
                            for i in 0...(roundsInRound - 1) {
                                let color = currentColorInstruction[i]
                                    
                                if color != "" {
                                    if !possibleColors.contains(color) {
                                        // Error. Wrong color, doesn't match convention
                                        redirectToOfflineMode()
                                        breakVar = true
                                        break
                                    } else {
                                        let nScore = currentScoreInstruction[i]
                                        
                                        // Sort holder data
                                        currentColorList.append(color)
                                        currentNScoreList.append(nScore)
                                        currentTimeList.append(ballTime)
                                        totalScore += nScore
                                    }
                                }
                            }
                            
                            if !breakVar {
                                allColorQueueList.append(currentColorList)
                                allScoreList.append(currentNScoreList)
                                allTimeList.append(currentTimeList)
                            } else {
                                break
                            }
                        }
                    }
                }
                
                self.messageLabel.displayMessage("Connected", duration: 3, gameName)
            }
        }
        
        disableUI(false)
    }
    
    /// Loads default elements in AR
    func loadReality() {
        // Assign entities
        // Boxes
        leftBox = experienceScene.leftBox!
        rightBox = experienceScene.rightBox!
        leftBoxUp = experienceScene.leftBoxUp!
        rightBoxUp = experienceScene.rightBoxUp!
        
        // Load balls
        blueBall = experienceScene.blueBall!
        brownBall = experienceScene.brownBall!
        cyanBall = experienceScene.cyanBall!
        greenBall = experienceScene.greenBall!
        greyBall = experienceScene.greyBall!
        orangeBall =  experienceScene.orangeBall!
        redBall = experienceScene.redBall!
        magentaBall = experienceScene.magentaBall!
        purpleBall = experienceScene.purpleBall!
        yellowBall = experienceScene.yellowBall!
        
        // Anchor entities
        characterAnchor.addChild(leftBox)
        characterAnchor.addChild(rightBox)
        characterAnchor.addChild(leftBoxUp)
        characterAnchor.addChild(rightBoxUp)
        characterAnchor.addChild(blueBall)
        characterAnchor.addChild(brownBall)
        characterAnchor.addChild(cyanBall)
        characterAnchor.addChild(greenBall)
        characterAnchor.addChild(greyBall)
        characterAnchor.addChild(orangeBall)
        characterAnchor.addChild(redBall)
        characterAnchor.addChild(magentaBall)
        characterAnchor.addChild(purpleBall)
        characterAnchor.addChild(yellowBall)
        
        // Add body tracked character and objects
        arView.scene.addAnchor(characterAnchor)
    }
    
    /// Loads body tracked robot character
    func loadRobot() {
        // Asynchronously load the 3D character.
        var cancellable: AnyCancellable? = nil
        cancellable = Entity.loadBodyTrackedAsync(named: "models/robot").sink(
            receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    // Model couldn't be lodad
                    print("Error: Unable to load model: \(error.localizedDescription)")
                }
                cancellable?.cancel()
        }, receiveValue: { (character: Entity) in
            if let character = character as? BodyTrackedEntity {
                // Scale the character to human size
                character.scale = [1.0, 1.0, 1.0]
                
                self.character = character
                cancellable?.cancel()
            } else {
                // Couldn't load model as a body
                print("Error: Unable to load model as BodyTrackedEntity")
            }
        })
    }
    
    // Loads tick sound
    func loadTickSound() {
        if let soundURL = Bundle.main.url(forResource: "tick", withExtension: "mp3") {
            do {
                tickPlayer = try AVAudioPlayer(contentsOf: soundURL)
            }
            catch {
                print(error)
            }
         } else {
            print("Unable to locate audio file")
         }
    }
    
    // Loads pass sound
    func loadPassSound() {
        if let soundURL = Bundle.main.url(forResource: "pass", withExtension: "mp3") {
            do {
                passPlayer = try AVAudioPlayer(contentsOf: soundURL)
            }
            catch {
                print(error)
            }
         } else {
            print("Unable to locate audio file")
         }
    }
    
    @IBAction func onBackButtonTap(_ sender: Any) {
        timer.invalidate()
    }
    
    @IBAction func onStartButtonTap(_ sender: Any) {
        startGame()
    }
    
    // Plays sounds
     func playSound(_ sound: String) {
         switch sound {
         case "hit":
             if let soundURL = Bundle.main.url(forResource: "hit", withExtension: "mp3") {
                 do {
                     audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                 }
                 catch {
                     print(error)
                 }
             } else {
                 print("Unable to locate audio file")
             }
         case "yay":
             if let soundURL = Bundle.main.url(forResource: "yay", withExtension: "mp3") {
                 do {
                     audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                 }
                 catch {
                     print(error)
                 }
             } else {
                 print("Unable to locate audio file")
             }
         case "aww":
            if let soundURL = Bundle.main.url(forResource: "aww", withExtension: "wav") {
                do {
                    audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                }
                catch {
                    print(error)
                }
             } else {
                print("Unable to locate audio file")
             }
         case "wrong":
            if let soundURL = Bundle.main.url(forResource: "wrong", withExtension: "mp3") {
                do {
                    audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                }
                catch {
                    print(error)
                }
             } else {
                print("Unable to locate audio file")
             }
         default:
             print("No sound found")
         }
        
        // Play sound
        audioPlayer.play()
     }
    
    /// Change game to next timer
    func nextTimer() {
        if !isOver {
            if allTimeList.isEmpty {
                // No more times. End game
                endGame()
            } else {
                // Change global timer to next
                currentColorQueueList.remove(at: 0)
                currentTimeList.remove(at: 0)
                currentScoreList.remove(at: 0)
                if currentTimeList.isEmpty {
                    // No more times. Change to next time and score list
                    allColorQueueList.remove(at: 0)
                    allScoreList.remove(at: 0)
                    allTimeList.remove(at: 0)
                    if allTimeList.isEmpty {
                        endGame()
                    } else {
                        currentColorQueueList = allColorQueueList[0]
                        currentScoreList = allScoreList[0]
                        currentTimeList = allTimeList[0]
                        seconds = currentTimeList[0]
                        passPlayer.play()
                    }
                } else {
                    // Set variable to be showed in UI
                    seconds = currentTimeList[0]
                }
            }
        }
    }
    
    /// Redirects game to offline mode
    func redirectToOfflineMode() {
        isOnline = false
        initializeOfflineAttributes()
        messageLabel.displayMessage("Error connecting. Offline.", duration: 10, gameName)
    }
    
    /// Shows animated view screen
    func showWinScreen() {
        animateQueueOutro()
        blurView.alpha = 0
        blurView.isHidden = false
        blurView.fadeIn()
        isOver = true
        scoreLabel.text = "Score: " + String(score)
        startButton.isEnabled = true
        
        // Update UI label depending on score
        let dScore = Double(score)
        let dTScore = Double(totalScore)
        if dScore < (dTScore * 0.25) {
            messageLabel.text = "What happened?"
            endGameLabel.text = "It's okay..."
            playSound("aww")
        } else if dScore < (dTScore * 0.5) {
            messageLabel.text = "Pff..."
            endGameLabel.text = "Not bad, but you can do better!"
            playSound("aww")
        } else if dScore < (dTScore * 0.75) {
            messageLabel.text = "Huh, good..."
            endGameLabel.text = "Great game!"
            playSound("yay")
        } else if dScore == dTScore {
            messageLabel.text = "Jelly baby?"
            endGameLabel.text = "Perfect score. Wow!"
            playSound("yay")
        }
    }
    
    /// Receives signal that ball has been touched/colided with
    func signalBall(_ color: String) {
        if !currentColorQueueList.isEmpty {
            // Check if hit is correct
            let headColor = currentColorQueueList[0]
            
            if headColor == color {
                // Hit was of correct color
                playSound("hit")
                score += currentScoreList[0]
                nextTimer()
                drawQueue()
            } else {
                // Hit was of wrong color
                playSound("wrong")
                messageLabel.displayMessage("Wrong color", duration: 1, gameName)
            }
        } else {
            print("Color queue is empty")
        }
    }

    /// Start collision detection system for current floating object
    func startCollisions() {
        // Subscribe scene to collision events
        // Blue ball
        arView.scene.subscribe(
            to: CollisionEvents.Began.self,
            on: blueBall
        ) { event in
            self.signalBall("blue")
        }.store(in: &collisionEventStreams)
        
        // Brown ball
        arView.scene.subscribe(
            to: CollisionEvents.Began.self,
            on: brownBall
        ) { event in
            self.signalBall("brown")
        }.store(in: &collisionEventStreams)
        
        // Cyan ball
        arView.scene.subscribe(
            to: CollisionEvents.Began.self,
            on: cyanBall
        ) { event in
            self.signalBall("cyan")
        }.store(in: &collisionEventStreams)
        
        // Green ball
        arView.scene.subscribe(
            to: CollisionEvents.Began.self,
            on: greenBall
        ) { event in
            self.signalBall("green")
        }.store(in: &collisionEventStreams)
        
        // Grey ball
        arView.scene.subscribe(
            to: CollisionEvents.Began.self,
            on: greyBall
        ) { event in
            self.signalBall("grey")
        }.store(in: &collisionEventStreams)
        
        // Magenta ball
        arView.scene.subscribe(
            to: CollisionEvents.Began.self,
            on: magentaBall
        ) { event in
            self.signalBall("magenta")
        }.store(in: &collisionEventStreams)
        
        // Orange ball
        arView.scene.subscribe(
            to: CollisionEvents.Began.self,
            on: orangeBall
        ) { event in
            self.signalBall("orange")
        }.store(in: &collisionEventStreams)
        
        // Purple ball
        arView.scene.subscribe(
            to: CollisionEvents.Began.self,
            on: purpleBall
        ) { event in
            self.signalBall("purple")
        }.store(in: &collisionEventStreams)
        
        // Red ball
        arView.scene.subscribe(
            to: CollisionEvents.Began.self,
            on: redBall
        ) { event in
            self.signalBall("red")
        }.store(in: &collisionEventStreams)
        
        // Yellow ball
        arView.scene.subscribe(
            to: CollisionEvents.Began.self,
            on: yellowBall
        ) { event in
            self.signalBall("yellow")
        }.store(in: &collisionEventStreams)
    }
    
    /// Starts game
    func startGame() {
        if !isOver {
            if !bodyAnchorExists {
                // Body doesn't yet exist
                messageLabel.displayMessage("No person detected", duration: 5, gameName)
            } else {
                // Timer and queue control
                startTimer()
                currentTimeList = allTimeList[0]
                currentScoreList = allScoreList[0]
                seconds = currentTimeList[0]
                
                // Draw Queue
                currentColorQueueList = allColorQueueList[0]
                drawQueue()

                // Animate queue entrance
                animateQueueIntro()
                
                // Start collision detection
                if isFirstTime {
                    startCollisions()
                    isFirstTime = false
                }
                
                startButton.isEnabled = false
            }
        } else {
            // Restart game
            blurView.fadeOut()
            isOver = false
            
            // Reinitialize attributes
            if isOnline! {
                initializeOnlineAttributes()
            } else {
                initializeOfflineAttributes()
            }
            
            startGame()
        }
    }
    
    /// Start timer for color queue
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(FloatingView.updateTimer)), userInfo: nil, repeats: true)
    }
    
    /// Runs every time timer is updated
    @objc func updateTimer() {
        seconds -= 1
        timerLabel.text = "Time: \(seconds)"
        tickPlayer.play()
        if seconds == 0 {
            // Time's up
            if allTimeList.isEmpty {
                // There are no more times. End session
                endGame()
            } else {
                // Change time
                nextTimer()
                drawQueue()
            }
        }
    }
    
    // MARK: - View Control
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Prevent screen lock
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Name anchors
        character?.name = "Jackie"
        characterAnchor.name = "Character Anchor"
        
        // Load Reality Composer scene and objects
        experienceScene = try! Experience.loadScene()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        arView.session.delegate = self
        
        // If the iOS device doesn't support body tracking, raise a developer error
        guard ARBodyTrackingConfiguration.isSupported else {
            fatalError("This feature is only supported on devices with an A12 chip")
        }

        // Run a body tracking configuration for session
        let configuration = ARBodyTrackingConfiguration()
        
        arView.session.run(configuration)
        
        // Load objects in scene
        loadObjects()
        
        // Initialize Attributes
        if isOnline! {
            initializeOnlineAttributes()
        } else {
            initializeOfflineAttributes()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arView.session.pause()
    }
    
    // MARK: - Session Control
    
    public func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        // Print when new anchor is added
        if !anchors.isEmpty {
            anchors.forEach { (anchor) in
                print("""
                      The Type Of Anchor = \(anchor.classForCoder)
                      The Anchor Identifier = \(anchor.identifier)
                      The Anchor Translation = X: \(anchor.transform.columns.3.x), Y: \(anchor.transform.columns.3.y), Z: \(anchor.transform.columns.3.z)
                      """)
                if anchor is ARBodyAnchor {
                    // ARBodyAnchor is detected. Notify class
                    bodyAnchorExists = true
                }
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        // Iterate over all detected anchors
        for anchor in anchors {
            if anchor is ARBodyAnchor {
                let bodyAnchor = anchor as! ARBodyAnchor
                
                // Tracked body data in skeleton
                let skeleton = bodyAnchor.skeleton
                
                // Obtain position and orientation with anchor data
                let bodyOrientation = Transform(matrix: bodyAnchor.transform).rotation
                let leftFootPos = simd_make_float3(skeleton.jointModelTransforms[5].columns.3)
                let rightFootPos = simd_make_float3(skeleton.jointModelTransforms[10].columns.3)
                let leftHandPos = simd_make_float3(skeleton.jointModelTransforms[29].columns.3)
                let rightHandPos = simd_make_float3(skeleton.jointModelTransforms[73].columns.3)
                let rootPos = simd_make_float3(skeleton.jointModelTransforms[0].columns.3)
                bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
                
                // Update position and orientation of elements
                characterAnchor.position = bodyPosition!
                characterAnchor.orientation = bodyOrientation
                
                // Balls for hands
                blueBall.position = rootPos + [0.5, 0, 0]
                brownBall.position = rootPos + [0.4, 0, 0.3]
                cyanBall.position = rootPos + [0, 0, 0.4]
                greenBall.position = rootPos + [-0.4, 0, 0.3]
                greyBall.position = rootPos + [-0.5, 0, 0]
                
                // Balls for feet
                magentaBall.position = rootPos + [0.5, -0.8, 0]
                orangeBall.position = rootPos + [0.4, -0.8, 0.3]
                purpleBall.position = rootPos + [0, -0.8, 0.4]
                redBall.position = rootPos + [-0.4, -0.8, 0.3]
                yellowBall.position = rootPos + [-0.5, -0.8, 0]
                
                leftBox.position = leftFootPos
                rightBox.position = rightFootPos
                leftBoxUp.position = leftHandPos
                rightBoxUp.position = rightHandPos
                
//                // Attach character to anchor
//                if let character = character, character.parent == nil {
//                    characterAnchor.addChild(character)
//                }
            }
        }
    }
    
}
