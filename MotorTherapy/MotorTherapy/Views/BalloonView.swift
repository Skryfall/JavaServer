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
    @IBOutlet weak var messageLabel: MessageLabel!
    @IBOutlet weak var startButton: UIButton!
    
    // MARK: - Attributes
    
    // Constants
    let gameName = "Balloon"
    
    // UI Views
    let coachingOverlay = ARCoachingOverlayView()
    
    // Entity data
    var bodyAnchorExists = false
    var character: BodyTrackedEntity?
    var headPos = simd_float3()
    var objectPos = simd_float3(-1, 0, 0)
    
    var instrumentList = [Entity]()
    var objectList = [Entity]()
    var currentInstrument = Entity()
    var currentObject = Entity()
    
    let characterAnchor = AnchorEntity()
    
    // Reality Composer scene
    var experienceScene = Experience.Scene()
    
    // Additional variables for control
    var audioPlayer: AVAudioPlayer!
    var currentIndex = 0
    var isFirstTime = true
    var isOnline: Bool?
    var isOver = false
    
    // Position info
    var posList = [[Double(), Double()]]
    var position: Any?
    var seconds = 0
    
    // Flush Collision events list for memory management
    var collisionEventStreams = [AnyCancellable]()
    deinit {
        collisionEventStreams.removeAll()
        endGame()
    }
    
    // MARK: - Functions
    
    /// Ends game
    func endGame() {
        showWinScreen()
    }
    
    /// Loads objects in scene
    func loadObjects() {
        loadReality()
        loadRobot()
    }
    
    /// Initializes attributes from server
    func initializeOfflineAttributes() {
        
        // PLACEHOLDER DATA FOR TESTS
        posList = [[0.5, 3], [-1, 4]]
        
        position = posList[0]
    }
    
    /// Initializes attributes from server
    func initializeOnlineAttributes() {
        
    }
    
    /// Loads default elements in AR
    func loadReality() {
        // Assign entities and model entities
        let balloon = experienceScene.balloon
        let racket = experienceScene.racket
        
        // Instruments
        let racketModel = ModelEntity()
        racketModel.addChild(racket!)
        
        // Objects
        let balloonModel = ModelEntity()
        balloonModel.addChild(balloon!)
        instrumentList.append(racketModel)
        
        // Default instrument and object
        currentInstrument = racket!
        currentObject = balloon!
        
        // Link current object with logical position
        objectPos = currentObject.position
        
        // Anchor entities
        characterAnchor.addChild(currentObject)
        characterAnchor.addChild(currentInstrument)
        
        // Add body tracked character
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
        
    }
    
    @IBAction func onStartButtonTap(_ sender: Any) {
        startGame()
    }
    
    /// Plays sounds
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
        default:
            print("No sound found")
        }
    }
    
    /// Shows animated view screen
    func showWinScreen() {
        blurView.alpha = 0
        blurView.isHidden = false
        blurView.fadeIn()
        isOver = true
        messageLabel.text = "Congratulations!"
        playSound("yay")
    }

    /// Start collision detection system for current floating object
    func startCollisions() {
        // Subscribe scene to collision events
        arView.scene.subscribe(
            to: CollisionEvents.Began.self,
            on: currentObject
        ) { event in
            //let object = event.entityA
            //let instrument = event.entityB
            
            self.nextObjectPosition()
            
        }.store(in: &collisionEventStreams)
    }
    
    /// Starts game
    func startGame() {
        if !isOver {
            if !bodyAnchorExists {
                // Body doesn't yet exist
                messageLabel.displayMessage("No person detected", duration: 5, gameName)
            } else {
                
                // Start collision detection
                if isFirstTime {
                    startCollisions()
                    isFirstTime = false
                }
                
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
                currentInstrument.position = rightHandMidStartPos
                
                characterAnchor.orientation = bodyOrientation
                currentInstrument.orientation = instrumentOrientation
                
                // Attach character to anchor
                if let character = character, character.parent == nil {
                    characterAnchor.addChild(character)
                }
            }
        }
    }
    
}
