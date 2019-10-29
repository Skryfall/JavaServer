//
//  FloatingView.swift
//  MotorTherapy
//
//  Created by Alejandro Ibarra on 10/27/19.
//  Copyright © 2019 Schlafenhase. All rights reserved.
//

import ARKit
import Combine
import RealityKit
import UIKit

class FloatingView: UIViewController, ARSessionDelegate {
    
    // MARK: - UI Elements
    
    // Main UI views
    @IBOutlet var arView: ARView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var controlView: UIView!
    
    // Buttons and other elements
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var messageLabel: MessageLabel!
    @IBOutlet weak var resetTrackingButton: UIButton!
    @IBOutlet weak var selectInstrumentButton: UIButton!
    
    // MARK: - Attributes
    
    // UI Views
    let coachingOverlay = ARCoachingOverlayView()
    
    // Entity data
    var character: BodyTrackedEntity?
    var headPos = simd_float3()
    
    var instrumentList = [Entity]()
    var objectList = [Entity]()
    var currentInstrument = Entity()
    var currentObject = Entity()
    
    let characterAnchor = AnchorEntity()
    var realityAnchor = AnchorEntity()
    
    var collisionEventStreams = [AnyCancellable]()
    
    // A tracked raycast which is used to place the character accurately
    // in the scene wherever the user taps.
    var placementRaycast: ARTrackedRaycast?
    var tapPlacementAnchor: AnchorEntity?
    
    // Reality Composer scene
    var experienceScene = Experience.Scene()
    
    /// Flush Collision events list for memory management
    deinit {
        collisionEventStreams.removeAll()
    }
    
    // MARK: - Functions
    
    /// Loads objects in scene
    func loadObjects() {
        loadReality()
        loadRobot()
    }
    
    /// Adds floating object to reality
    func addObject() {
        if (headPos.x == 0 && headPos.y == 0 && headPos.z == 0) {
            // Body doesn't yet exist
        } else {
            print("Moving object")
            currentObject.position = headPos
        }
    }
    
    /// Loads default elements in AR
    func loadReality() {
        // Assign entities and model entities
        let balloon = experienceScene.balloon
        let racket = experienceScene.racket
        
        // Assign components from Reality Composer Entity to full ModelEntity object
        
        // Instruments
        let racketModel = ModelEntity()
        racketModel.addChild(racket!)
        
        // Objects
        let balloonModel = ModelEntity()
        balloonModel.addChild(balloon!)
        instrumentList.append(racketModel)
        
        // Default instrument and object
//        currentInstrument = racketModel
//        currentObject = balloonModel
        currentInstrument = racket!
        currentObject = balloon!
        
        // Anchor entities
        //realityAnchor.addChild(currentObject)
        characterAnchor.addChild(currentObject)
        characterAnchor.addChild(currentInstrument)
        
        // Add body tracked character
        arView.scene.addAnchor(characterAnchor)
        arView.scene.addAnchor(realityAnchor)
    }
    
    /// Loads body tracked robot character
    func loadRobot() {
        // Asynchronously load the 3D character.
        var cancellable: AnyCancellable? = nil
        cancellable = Entity.loadBodyTrackedAsync(named: "models/robot").sink(
            receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error: Unable to load model: \(error.localizedDescription)")
                }
                cancellable?.cancel()
        }, receiveValue: { (character: Entity) in
            if let character = character as? BodyTrackedEntity {
                // Scale the character to human size
                character.scale = [1.0, 1.0, 1.0]
                //character.scale = [0.4, 0.4, 0.4]
                self.character = character
                cancellable?.cancel()
            } else {
                print("Error: Unable to load model as BodyTrackedEntity")
            }
        })
    }
    
    @IBAction func onAddButtonTap(_ sender: Any) {
        addObject()
    }
    
    @IBAction func onResetButtonTap(_ sender: Any) {
        resetTracking()
    }

    /// Resets AR tracking in session
    func resetTracking() {
        // Remove scene anchors
        arView.scene.anchors.removeAll()
        
        // Start coaching
        setupCoachingOverlay()
    }
    
    func startCollisions() {
        arView.scene.subscribe(
            to: CollisionEvents.Began.self,
            on: currentObject
        ) { event in
            //let object = event.entityA as? AnchorEntity
            //let instrument = event.entityB as? AnchorEntity
            
            print("OBJECT")
            print(event.entityA.name)
            print(event.entityB.name)
            print("END OBJECT")
        }.store(in: &collisionEventStreams)
    }
    
    // MARK: - View Control
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Prevent screen lock
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Name anchors
        character?.name = "Paul"
        characterAnchor.name = "Character Anchor"
        realityAnchor.name = "Reality Anchor"
        
        // Load Reality Composer scene and objects
        experienceScene = try! Experience.loadScene()
        
        // Start coaching
        //setupCoachingOverlay()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        arView.session.delegate = self
        
        // If the iOS device doesn't support body tracking, raise a developer error.
        guard ARBodyTrackingConfiguration.isSupported else {
            fatalError("This feature is only supported on devices with an A12 chip")
        }

        // Run a body tracking configuration.
        let configuration = ARBodyTrackingConfiguration()
        configuration.automaticSkeletonScaleEstimationEnabled = true
        arView.session.run(configuration)
        
        // TEST
        loadObjects()
        
        // Start collision detection system
        startCollisions()
            
//        print("ANCHORS ONE")
//        print(arView.scene.anchors)
//        print("END ONE")
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
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
//        print("ANCHORS TWO")
//        print(arView.scene.anchors)
//        print("END TWO")
        
        for anchor in anchors {
//            print("READING ANCHOR")
//            print(anchor)
//            print("READ ANCHOR")
            if anchor is ARBodyAnchor {
                let bodyAnchor = anchor as! ARBodyAnchor
                
                // Tracked body data in skeleton
                let skeleton = bodyAnchor.skeleton
                
                // Update position and orientation of elements
                let bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
                let rightHandMidStartPos = simd_make_float3(skeleton.jointModelTransforms[72].columns.3)
                let rightHandThumbEndPos = simd_make_float3(skeleton.jointModelTransforms[90].columns.3)
                
                let bodyOrientation = Transform(matrix: bodyAnchor.transform).rotation
                let instrumentOrientation = simd_quatf(from: rightHandMidStartPos, to: rightHandThumbEndPos)
                
                characterAnchor.position = bodyPosition
                // + characterOffset
                currentInstrument.position = rightHandMidStartPos
                
                characterAnchor.orientation = bodyOrientation
                currentInstrument.orientation = instrumentOrientation
                
                headPos = rightHandMidStartPos
                //bodyPosition + [0, 1.5, 0]
                
                // Attach character to anchor
                if let character = character, character.parent == nil {
                    characterAnchor.addChild(character)
                }
            }
        }
    }

}
