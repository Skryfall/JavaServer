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
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var resetTrackingButton: UIButton!
    @IBOutlet weak var messageLabel: MessageLabel!
    
    // MARK: - Attributes
    
    // UI Views
    let coachingOverlay = ARCoachingOverlayView()
    
    // Entity data
    var balloon: Entity?
    var balloonModel = ModelEntity()
    var box: Entity?
    var character: BodyTrackedEntity?
    var racket: Entity?
    var racketModel = ModelEntity()
    
    let characterAnchor = AnchorEntity()
    var realityAnchor = AnchorEntity()
    
    let characterOffset: SIMD3<Float> = [0, 0, 0] // Offset robot position
    var planePos: SIMD3<Float> = [0, 0, 0]
    
    // A tracked raycast which is used to place the character accurately
    // in the scene wherever the user taps.
    var placementRaycast: ARTrackedRaycast?
    var tapPlacementAnchor: AnchorEntity?
    
    // Reality Composer scene
    var experienceScene = Experience.Scene()
    
    // MARK: - Functions
    
    /// Adds objects to scene
    func addObjects() {
        loadReality()
        loadRobot()
    }
    
    /// Loads default elements in AR
    func loadReality() {
        // Assign entities and model entities
        balloon = experienceScene.balloon
        box = experienceScene.box
        racket = experienceScene.racket
        
        // Assign components from Reality Composer Entity to full ModelEntity object
        balloonModel.addChild(balloon!)
        racketModel.addChild(racket!)
        
        // Anchor entities
        //realityAnchor.addChild(balloonModel)
        //realityAnchor.addChild(box!)
        characterAnchor.addChild(racketModel)
        arView.scene.addAnchor(realityAnchor)
        
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
        configuration.planeDetection = .horizontal
        arView.session.run(configuration)
        
        // Add gestures to elements
        arView.installGestures(.all, for: balloonModel)
        
        // TEST
        loadRobot()
        loadReality()
            
        print("ANCHORS ONE")
        print(arView.scene.anchors)
        print("END ONE")
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
        
        for anchor in anchors {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
            
            print("PLANE ANCHOR HAS BEEN ADDED")
            
            // Measure plane dimensions
            let width = CGFloat(planeAnchor.extent.x)
            let height = CGFloat(planeAnchor.extent.z)
            let plane = SCNPlane(width: width, height: height)
            
            // Change plane material/color
            plane.materials.first?.diffuse.contents = UIColor.blue
            
            // 4
            let planeNode = SCNNode(geometry: plane)
            
            // 5
            let x = CGFloat(planeAnchor.center.x)
            let y = CGFloat(planeAnchor.center.y)
            let z = CGFloat(planeAnchor.center.z)
            planeNode.position = SCNVector3(x,y,z)
            planeNode.eulerAngles.x = -.pi / 2
            
            // 6
            //node.addChildNode(planeNode)
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
                //let rightHandPos = simd_make_float3(skeleton.modelTransform(for: .rightHand)!.columns.3)
                let rightHandPos = simd_make_float3(skeleton.jointModelTransforms[73].columns.3)
                
                //let headPos = simd_make_float3(skeleton.modelTransform(for: .head)!.columns.3)
                
                let midFingerPos = simd_make_float3(skeleton.jointModelTransforms[75].columns.3)
            
                
                characterAnchor.position = bodyPosition
                //+ characterOffset
                racketModel.position = rightHandPos

                let bodyOrientation = Transform(matrix: bodyAnchor.transform).rotation
                
                let racketOrientation = simd_quatf(from: rightHandPos, to: midFingerPos)
                
                print("START TRANSFORMS")
                //print(bodyOrientation)
                print(racketOrientation.axis)
                print(racketOrientation.vector)
                print("END TRANSFORMS")
                
                characterAnchor.orientation = bodyOrientation
                racketModel.orientation = racketOrientation
                    
                // Attach character to anchor
                if let character = character, character.parent == nil {
                    characterAnchor.addChild(character)
                }
            } else if anchor is ARPlaneAnchor {
                
//                print("PLANE ANCHOR DETECTED")
//                print(anchor)
//                print("END PLANE ANCHOR DETECTION")
                
                let planeAnchor = anchor
                
                planePos = simd_make_float3(planeAnchor.transform.columns.3)
                box?.position = planePos
                balloonModel.position = planePos
            }
        }
    }

}
