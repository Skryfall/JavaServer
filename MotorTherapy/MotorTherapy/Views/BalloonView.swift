//
//  BalloonView.swift
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

class BalloonView: UIViewController, ARSessionDelegate {
    
    // MARK: - UI Elements
    
    // Main UI views
    @IBOutlet var arView: ARView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var controlView: UIView!
    
    // Buttons and other elements
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var endGameLabel: UILabel!
    @IBOutlet weak var messageLabel: MessageLabel!
    @IBOutlet weak var startButton: UIButton!
    
    // MARK: - Attributes
    
    // Constants
    let gameName = "Balloon"
    
    // Entity data
    var bodyAnchorExists = false
    var character: BodyTrackedEntity?
    var headPos = simd_float3()
    var objectPos = simd_float3(-1, 0, 0)
    
    var balloonEntity = Entity()
    var rightRacket = Entity()
    var leftRacket = Entity()
    
    let characterAnchor = AnchorEntity()
    
    // Reality Composer scene
    var experienceScene = Experience.Scene()
    
    // Additional variables for control
    var audioPlayer: AVAudioPlayer!
    var currentIndex = 0
    var holder = Holder()
    var isFirstTime = true
    var isAnimating = false
    var isOnline: Bool?
    var isOver = false
    var rounds = 0
    var seconds = 0
    var timer = Timer()
    
    // Offline posibilities for variables
    let possibleRounds = [2, 3, 4, 5]
    let possibleX = [0.5, 0.2, -0.6, -0.2, 0.6, -0.7]
    let possibleY = [1, 1.3, 1.2, 1.5]
    let possibleZ = [0.2, 0.3, -0.2, -0.3, 0.1]
    
    // Position and timer info
    var allPosList = [[Float(), Float(), Float()]]
    var currentPosList = [Float()]
    
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
        showWinScreen()
    }
    
    /// Loads objects in scene
    func loadObjects() {
        loadReality()
        loadRobot()
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
        }
        
        messageLabel.displayMessage("Loaded", duration: 3, gameName)
    }
    
    /// Initializes attributes from server
    func initializeOnlineAttributes() {
        // Connect to server to update holder
        messageLabel.text = "Connecting..."
        disableUI(true)
        
        do{
            holder = connectToServer()
            if !holder.connectionSuccess! {
                // Error connecting. Redirect to offline mode
                redirectToOfflineMode()
            } else {
                // Connection to server success
                let objectInstructions = holder.balloonInstructions
                
                for i in objectInstructions! {
                    if i.count != 3 {
                        // Error. Data doesn't match convention
                        redirectToOfflineMode()
                        break
                    } else {
                        // Sort holder data
                        var x = Float(i[0]) / 10
                        var y = Float(i[1]) / 10
                        var z = Float(i[2]) / 10
                        
                        // Correct numbers if out of range to known working values
                        if x > 0.7 || x < -0.7 {
                            x = Float(possibleX.randomElement()!)
                        } else if y > 1.5 || y < 1 {
                            y = Float(possibleY.randomElement()!)
                        } else if z > 0.3 || z < -0.3 {
                            z = Float(possibleZ.randomElement()!)
                        }
                        
                        let pos = [x, y, z]
                        allPosList.append(pos)
                        rounds = allPosList.count
                    }
                }
                
                print(allPosList)
                
                self.messageLabel.displayMessage("Connected", duration: 3, gameName)
            }
        }
        
        disableUI(false)
    }
    
    /// Loads default elements in AR
    func loadReality() {
        // Assign entities
        let balloon = experienceScene.balloon
        let racket = experienceScene.racket
        let racket2 = experienceScene.racket2
        
        // Default instrument and object
        leftRacket = racket2!
        rightRacket = racket!
        balloonEntity = balloon!
        
        // Link current object with logical position
        objectPos = balloonEntity.position
        
        // Anchor entities
        characterAnchor.addChild(balloonEntity)
        characterAnchor.addChild(leftRacket)
        characterAnchor.addChild(rightRacket)
        
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
                    balloonEntity.position = newPos
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
        isOver = true
        startButton.isEnabled = true
    }

    /// Start collision detection system for current floating object
    func startCollisions() {
        // Subscribe scene to collision events
        arView.scene.subscribe(
            to: CollisionEvents.Began.self,
            on: balloonEntity
        ) { event in
            if self.isAnimating == false {
                self.isAnimating = true
            }
            self.startTimer()
        }.store(in: &collisionEventStreams)
    }
    
    /// Starts game
    func startGame() {
        if !isOver {
            if !bodyAnchorExists {
                // Body doesn't yet exist
                messageLabel.displayMessage("No person detected", duration: 5, gameName)
            } else {
                // Position control
                currentPosList = allPosList[0]
                
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
            
            // Position control
            currentPosList = allPosList[0]
        }
    }
    
    /// Start timer for object movement
    func startTimer() {
        playSound("hit")
        if !timer.isValid {
            timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: (#selector(BalloonView.updateTimer)), userInfo: nil, repeats: true)
        }
    }
    
    /// Runs every time timer is updated
    @objc func updateTimer() {
        seconds += 1
        
        if isAnimating {
            // Animation in progress. Move object vertically
            balloonEntity.position += [0, balloonEntity.position.y + 0.001, 0]
        }
        
        if seconds == 4 {
            // End animation and go to next round
            timer.invalidate()
            nextObjectPosition()
            seconds = 0
            isAnimating = false
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
                let bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
                let leftHandMidStartPos = simd_make_float3(skeleton.jointModelTransforms[28].columns.3)
                let leftHandThumbEndPos = simd_make_float3(skeleton.jointModelTransforms[46].columns.3)
                let rightHandMidStartPos = simd_make_float3(skeleton.jointModelTransforms[72].columns.3)
                let rightHandThumbEndPos = simd_make_float3(skeleton.jointModelTransforms[90].columns.3)
                headPos = simd_make_float3(skeleton.jointModelTransforms[51].columns.3)
                
                let bodyOrientation = Transform(matrix: bodyAnchor.transform).rotation
                let leftRacketOrientation = simd_quatf(from: leftHandMidStartPos, to: leftHandThumbEndPos)
                let rightRacketOrientation = simd_quatf(from: rightHandMidStartPos, to: rightHandThumbEndPos)
                
                // Update position and orientation of elements
                characterAnchor.position = bodyPosition
                leftRacket.position = leftHandMidStartPos
                rightRacket.position = rightHandMidStartPos
                
                characterAnchor.orientation = bodyOrientation
                leftRacket.orientation = leftRacketOrientation
                rightRacket.orientation = rightRacketOrientation
                
                // Attach character to anchor
//                if let character = character, character.parent == nil {
//                    characterAnchor.addChild(character)
//                }
            }
        }
    }
    
}
