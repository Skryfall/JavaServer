//
//  FloatingView.swift
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

class FloatingView: UIViewController, ARSessionDelegate {
    
    // MARK: - UI Elements
    
    // TEMP
    let coachingOverlay = ARCoachingOverlayView()
    
    // Main UI views
    @IBOutlet var arView: ARView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var controlView: UIView!
    
    // Buttons and other elements
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var endGameLabel: UILabel!
    @IBOutlet weak var objectButton: UIButton!
    @IBOutlet weak var messageLabel: MessageLabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var selectInstrumentButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var timerLabel: UILabel!
    
    // MARK: - Attributes
    
    // Constants
    let gameName = "Floating Object"
    
    // Entity data
    var bodyAnchorExists = false
    var character: BodyTrackedEntity?
    var headPos = simd_float3()
    var objectPos = simd_float3(-1, 0, 0)
    
    var floatingObject = Entity()
    var floatingObjectList = [Entity]()
    var instrument = Entity()
    var instrumentList = [Entity]()
    
    let characterAnchor = AnchorEntity()
    
    // Reality Composer scene
    var experienceScene = Experience.Scene()
    
    // Additional variables for control
    var audioPlayer: AVAudioPlayer!
    var currentIndex = 0
    var holder: Holder?
    var isFirstTime = true
    var isOnline: Bool?
    var isOver = false
    var rounds = 0
    var score = 0
    var tickPlayer = AVAudioPlayer()
    var tockPlayer = AVAudioPlayer()
    var totalScore = 0
    
    // Offline posibilities for variables
    let possibleRounds = [2, 3, 4, 5]
    let possibletimeList = [5, 6, 7, 9, 10]
    let possibleX = [0.5, 0.2, -0.6, -0.2, 0.6, -0.7]
    let possibleY = [1, 1.3, 1.2, 1.5,]
    let possibleZ = [0.2, 0.3, -0.2, -0.3, 0.1]
    
    // Position and timer info
    var allPosList = [[Float(), Float(), Float()]]
    var currentPosList = [Float()]
    var timer = Timer()
    var timeList = [Int]()
    var seconds = 0
    
    // Flush Collision events list for memory management
    var collisionEventStreams = [AnyCancellable]()
    deinit {
        collisionEventStreams.removeAll()
        endGame()
    }
    
    // MARK: - Functions
    
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
    
    /// Ends game
    func endGame() {
        timer.invalidate()
        showWinScreen()
        score = 0
    }
    
    /// Loads objects in scene
    func loadObjects() {
        loadReality()
        loadRobot()
        loadTickSound()
        loadTockSound()
    }
    
    /// Initializes attributes from local randomizer
    func initializeOfflineAttributes() {
        messageLabel.text = "Loading..."
        rounds = possibleRounds.randomElement()!
        
        for _ in 1...rounds {
            // Randomize position
            let x = Float(possibleX.randomElement()!)
            let y = Float(possibleY.randomElement()!)
            let z = Float(possibleZ.randomElement()!)
            let pos = [x, y, z]
            allPosList.append(pos)
            
            // Randomize time
            let time = possibletimeList.randomElement()
            timeList.append(time!)
            totalScore += time!
        }
        
        messageLabel.displayMessage("Loaded", duration: 3, gameName)
    }
    
    /// Initializes attributes from server
    func initializeOnlineAttributes() {
        // Connect to server to update holder
        messageLabel.text = "Connecting..."
        disableUI(true)
        
        do{
            holder = try connectToServer()
            if !holder!.connectionSuccess! {
                // Error connecting. Redirect to offline mode
                redirectToOfflineMode()
            } else {
                // Connection to server success
                let objectInstructions = holder?.objectInstructions
                
                for i in objectInstructions! {
                    if i.count != 4 {
                        // Error. Data doesn't match convention
                        redirectToOfflineMode()
                    } else {
                        // Sort holder data
                        let pos = [Float(i[0]), Float(i[1]), Float(i[2])]
                        allPosList.append(pos)
                        let time = i[3]
                        timeList.append(time)
                        totalScore += time
                        rounds = allPosList.count
                    }
                }
                
                self.messageLabel.displayMessage("Connected", duration: 3, gameName)
            }
        } catch let error {
            // Catch errors
            print(error)
            self.messageLabel.displayMessage("Error. Try again", duration: 10, gameName)
        }
        
        disableUI(false)
    }
    
    /// Loads default elements in AR
    func loadReality() {
        // Assign entities
        let balloon = experienceScene.balloon
        let racket = experienceScene.racket
        
        // Default instrument and object
        instrument = racket!
        floatingObject = balloon!
        
        instrumentList.append(instrument)
        floatingObjectList.append(floatingObject)
        
        // Link current object with logical position
        objectPos = floatingObject.position
        
        // Anchor entities
        characterAnchor.addChild(floatingObject)
        characterAnchor.addChild(instrument)
        
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
    
    // Loads tock sound
    func loadTockSound() {
        if let soundURL = Bundle.main.url(forResource: "tock", withExtension: "mp3") {
            do {
                tockPlayer = try AVAudioPlayer(contentsOf: soundURL)
            }
            catch {
                print(error)
            }
         } else {
            print("Unable to locate audio file")
         }
    }
    
    /// Change object position to next one in list
    func nextObjectPosition() {
        if !isOver {
            if allPosList.isEmpty {
                // No more positions. End game
                endGame()
            } else {
                // Remove old position
                allPosList.remove(at: 0)
                if allPosList.isEmpty {
                    // No more positions. End game
                    endGame()
                } else {
                    // Move object
                    currentPosList = allPosList[0]
                    let newPos = simd_float3(currentPosList[0], currentPosList[1], currentPosList[2])
                    floatingObject.position = newPos
                }
            }
        }
    }
    
    /// Change game to next timer
    func nextTimer() {
        if !isOver {
            // Assign score
            score += seconds
            
            if timeList.isEmpty {
                // No more times. End game
                endGame()
            } else {
                // Change global timer to next
                timeList.remove(at: 0)
                if timeList.isEmpty {
                    // No more times. End game
                    endGame()
                } else {
                    // Set variable to be showed in UI
                    seconds = timeList[0]
                }
            }
        }
    }
    
    @IBAction func onObjectButtonTap(_ sender: Any) {
        
    }
    
    @IBAction func onSelectInstrumentButtonTap(_ sender: Any) {
        
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
                audioPlayer.play()
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
                audioPlayer.play()
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
                audioPlayer.play()
            } else {
                print("Unable to locate audio file")
            }
        default:
            print("No sound found")
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
        blurView.alpha = 0
        blurView.isHidden = false
        blurView.fadeIn()
        scoreLabel.text = "Score: " + String(score)
        isOver = true
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

    /// Start collision detection system for current floating object
    func startCollisions() {
        // Subscribe scene to collision events
        arView.scene.subscribe(
            to: CollisionEvents.Began.self,
            on: floatingObject
        ) { event in
            self.nextTimer()
            self.nextObjectPosition()
            self.playSound("hit")
        }.store(in: &collisionEventStreams)
    }
    
    /// Starts game
    func startGame() {
        if !isOver {
            if !bodyAnchorExists {
                // Body doesn't yet exist
                messageLabel.displayMessage("No person detected", duration: 5, gameName)
            } else {
                // Start timer and position control
                startTimer()
                currentPosList = allPosList[0]
                seconds = timeList[0]
                
                // Move object to first position
                nextObjectPosition()
                
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
            
            // Start timer and position control
            startTimer()
            currentPosList = allPosList[0]
            seconds = timeList[0]
        }
    }
    
    /// Start timer for floating object
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
            if timeList.isEmpty {
                // There are no more times. End session
                endGame()
            } else {
                // Change object position and time
                nextTimer()
                nextObjectPosition()
                tockPlayer.play()
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
        configuration.automaticSkeletonScaleEstimationEnabled = true
        
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
                let bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
                let rightHandMidStartPos = simd_make_float3(skeleton.jointModelTransforms[72].columns.3)
                let rightHandThumbEndPos = simd_make_float3(skeleton.jointModelTransforms[90].columns.3)
                headPos = simd_make_float3(skeleton.jointModelTransforms[51].columns.3)
                
                let bodyOrientation = Transform(matrix: bodyAnchor.transform).rotation
                let instrumentOrientation = simd_quatf(from: rightHandMidStartPos, to: rightHandThumbEndPos)
                
                // Update position and orientation of elements
                characterAnchor.position = bodyPosition
                instrument.position = rightHandMidStartPos
                
                characterAnchor.orientation = bodyOrientation
                instrument.orientation = instrumentOrientation
                
                // Attach character to anchor
                if let character = character, character.parent == nil {
                    characterAnchor.addChild(character)
                }
            }
        }
    }
    
}
