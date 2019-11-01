//
//  SpiderView.swift
//  MotorTherapy
//
//  Created by Alejandro Ibarra on 10/29/19.
//  Copyright © 2019 Schlafenhase. All rights reserved.
//

import ARKit
import Combine
import RealityKit
import UIKit

class SpiderView: UIViewController, ARSessionDelegate {
    
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
    
    // Entity data
    var bodyAnchorExists = false
    var bodyPosition: simd_float3?
    var character: BodyTrackedEntity?
    let characterAnchor = AnchorEntity()
    var upBall = Entity()
    var downBall = Entity()
    var leftBall = Entity()
    var rightBall = Entity()
    var leftBox = Entity()
    var rightBox = Entity()
    
    // Reality Composer scene
    var experienceScene = Experience.Scene()
    
    // Flush Collision events list for memory management
    var collisionEventStreams = [AnyCancellable]()
    deinit {
        collisionEventStreams.removeAll()
    }
    
    // MARK: - Functions
    
    /// Ends game
    func endGame() {
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
    }
    
    /// Loads default elements in AR
    func loadReality() {
        // Assign entities and model entities
        upBall = experienceScene.upBall!
        downBall = experienceScene.downBall!
        leftBall = experienceScene.leftBall!
        rightBall = experienceScene.rightBall!
        leftBox = experienceScene.leftBox!
        rightBox = experienceScene.rightBox!
        
        // Anchor entities
        characterAnchor.addChild(upBall)
        characterAnchor.addChild(downBall)
        characterAnchor.addChild(leftBall)
        characterAnchor.addChild(rightBall)
        characterAnchor.addChild(leftBox)
        characterAnchor.addChild(rightBox)
        
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
    
    @IBAction func onStartButtonTap(_ sender: Any) {
        startGame()
    }

    /// Start collision detection system for current floating object
    func startCollisions() {
        // Subscribe scene to collision events
        // Signal up
        arView.scene.subscribe(
            to: CollisionEvents.Began.self,
            on: upBall
        ) { event in
            self.signalUp()
        }.store(in: &collisionEventStreams)
        
        // Signal down
        arView.scene.subscribe(
            to: CollisionEvents.Began.self,
            on: downBall
        ) { event in
            self.signalDown()
        }.store(in: &collisionEventStreams)
        
        // Signal left
        arView.scene.subscribe(
            to: CollisionEvents.Began.self,
            on: leftBall
        ) { event in
            self.signalLeft()
        }.store(in: &collisionEventStreams)
        
        // Signal right
        arView.scene.subscribe(
            to: CollisionEvents.Began.self,
            on: rightBall
        ) { event in
            self.signalRight()
        }.store(in: &collisionEventStreams)
    }
    
    /// Signal down movement in UI
    func signalDown() {
        print("DOWN HAS BEEN TOUCHED")
    }
    
    /// Signal left movement in UI
    func signalLeft() {
        print("LEFT HAS BEEN TOUCHED")
    }
    
    /// Signal right movement in UI
    func signalRight() {
        print("RIGHT HAS BEEN TOUCHED")
    }
    
    /// Signal up movement in UI
    func signalUp() {
        print("UP HAS BEEN TOUCHED")
    }
    
    /// Starts game
    func startGame() {
        if !bodyAnchorExists {
            // Body doesn't yet exist
            messageLabel.text = "No person detected"
        } else {
            
            
            // Start collision detection
            startCollisions()
            
            startButton.isEnabled = false
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
        
        // Enable people occlusion with depth for a cooler experience
        configuration.frameSemantics.insert(.personSegmentationWithDepth)
        
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
                let bodyOrientation = Transform(matrix: bodyAnchor.transform).rotation
                let leftHandMidStartPos = simd_make_float3(skeleton.jointModelTransforms[29].columns.3)
                let rightHandMidStartPos = simd_make_float3(skeleton.jointModelTransforms[73].columns.3)
                let rootPos = simd_make_float3(skeleton.jointModelTransforms[0].columns.3)
                bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
                
                // Update position and orientation of elements
                characterAnchor.position = bodyPosition!
                characterAnchor.orientation = bodyOrientation
                
                // Place balls in the air
                upBall.position = rootPos + [0, 0, 0.3]
                leftBall.position = rootPos + [0.7, 0, 0]
                rightBall.position = rootPos + [-0.7, 0, 0]
                downBall.position = rootPos + [0, 0, -0.3]
                leftBox.position = leftHandMidStartPos
                rightBox.position = rightHandMidStartPos
                
                
                // Attach character to anchor
                if let character = character, character.parent == nil {
                    characterAnchor.addChild(character)
                }
            }
        }
    }
    
}
