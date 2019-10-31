//
//  FloatingView.swift
//  MotorTherapy
//
//  Created by Alejandro Ibarra on 10/29/19.
//  Copyright © 2019 Schlafenhase. All rights reserved.
//

import ARKit
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
    @IBOutlet weak var objectButton: UIButton!
    @IBOutlet weak var messageLabel: MessageLabel!
    @IBOutlet weak var selectInstrumentButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var timerLabel: UILabel!
    
    // MARK: - Attributes
    
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
    
    // Track current index of pos and timer
    var currentIndex = 0
    
    // Position and timer info
    var posList = [[Double(), Double()]]
    var timer = Timer()
    var timeList = [Int]()
    var position: Any?
    var seconds = 0
    
    // Flush Collision events list for memory management
    var collisionEventStreams = [AnyCancellable]()
    deinit {
        collisionEventStreams.removeAll()
    }
    
    // MARK: - Functions
    
    /// Ends game
    func endGame() {
        timer.invalidate()
        messageLabel.text = "You win"
    }
    
    /// Loads objects in scene
    func loadObjects() {
        loadReality()
        loadRobot()
    }
    
    /// Initializes attributes from server
    func initializeAttributes() {
        
        // PLACEHOLDER DATA FOR TESTS
        timeList = [5, 5, 10, 20]
        posList = [[0.5, 3], [-1, 4]]
        
        seconds = timeList[0]
        position = posList[0]
    }
    
    /// Loads default elements in AR
    func loadReality() {
        // Assign entities and model entities
        let balloon = experienceScene.balloon
        let racket = experienceScene.racket
        
        // Default instrument and object
        currentInstrument = racket!
        currentObject = balloon!
        
        instrumentList.append(currentInstrument)
        objectList.append(currentObject)
        
        // Link current object with logical position
        objectPos = currentObject.position
        
        // Anchor entities
        characterAnchor.addChild(currentObject)
        characterAnchor.addChild(currentInstrument)
        
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
    
    /// Moves object to position in 3D space
    func moveObject(newPos: simd_float3) {
        currentObject.position = newPos
    }
    
    /// Change object position to next one in list
    func nextObjectPosition() {
        
    }
    
    /// Change game to next timer
    func nextTimer() {
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
    
    @IBAction func onObjectButtonTap(_ sender: Any) {
        
    }
    
    @IBAction func onSelectInstrumentButtonTap(_ sender: Any) {
        
    }
    
    @IBAction func onStartButtonTap(_ sender: Any) {
        startGame()
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
            
            self.nextTimer()
            self.nextObjectPosition()
            
        }.store(in: &collisionEventStreams)
    }
    
    /// Starts game
    func startGame() {
        if !bodyAnchorExists {
            // Body doesn't yet exist
            messageLabel.text = "No person detected"
        } else {
            moveObject(newPos: headPos + [0, 0.5, 0])
            // Start object timer
            startTimer()
            
            // Start collision detection
            startCollisions()
            
            startButton.isEnabled = false
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
        if seconds == 0 {
            // Time's up
            if timeList.isEmpty {
                // There are no more times. End session
                endGame()
            } else {
                // Change object position and time
                nextTimer()
                nextObjectPosition()
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
        
        // Initialize Attributes from server
        initializeAttributes()
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
