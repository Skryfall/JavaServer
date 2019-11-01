//
//  FeetView.swift
//  MotorTherapy
//
//  Created by Alejandro Ibarra on 10/29/19.
//  Copyright © 2019 Schlafenhase. All rights reserved.
//

import ARKit
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
    @IBOutlet weak var messageLabel: MessageLabel!
    @IBOutlet weak var startButton: UIButton!
    
    // Queue views
    @IBOutlet weak var queueColor1: UIImageView!
    @IBOutlet weak var queueColor2: UIImageView!
    @IBOutlet weak var queueColor3: UIImageView!
    @IBOutlet weak var queueColor4: UIImageView!
    
    // MARK: - Attributes
    
    // Entity data
    var bodyAnchorExists = false
    var bodyPosition: simd_float3?
    var character: BodyTrackedEntity?
    let characterAnchor = AnchorEntity()
    var leftBox = Entity()
    var rightBox = Entity()
    
    // Queue management
    var queueList = [[String]]()
    var currentQueue = [String]()
    
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
    func animateQueueEntrance() {
        
    }
    
    /// Draws color in flag queue view
    func drawQueue() {
        let color1: String?
        let color2: String?
        let color3: String?
        let color4: String?
        if currentQueue.isEmpty {
            queueList.remove(at: 0)
            if queueList.isEmpty {
                // No more colors. End game
                endGame()
            } else {
                // Change queue
                currentQueue = queueList[0]
                drawQueue()
            }
        } else if currentQueue.count == 3 {
            // Only 3 colors to be showed
            color1 = currentQueue[0]
            color2 = currentQueue[1]
            color3 = currentQueue[2]
            queueColor1.backgroundColor = getColor(color: color1!)
            queueColor2.backgroundColor = getColor(color: color2!)
            queueColor3.backgroundColor = getColor(color: color3!)
            queueColor4.backgroundColor = .clear
        } else if currentQueue.count == 2 {
            // Only 2 colors to be showed
            color1 = currentQueue[0]
            color2 = currentQueue[1]
            queueColor1.backgroundColor = getColor(color: color1!)
            queueColor2.backgroundColor = getColor(color: color2!)
            queueColor3.backgroundColor = .clear
            queueColor4.backgroundColor = .clear
        } else if currentQueue.count == 1 {
            // Only 1 color to be showed
            color1 = currentQueue[0]
            queueColor1.backgroundColor = getColor(color: color1!)
            queueColor2.backgroundColor = .clear
            queueColor3.backgroundColor = .clear
            queueColor4.backgroundColor = .clear
        } else {
            // All colors to be showed
            color1 = currentQueue[0]
            color2 = currentQueue[1]
            color3 = currentQueue[2]
            color4 = currentQueue[3]
            queueColor1.backgroundColor = getColor(color: color1!)
            queueColor2.backgroundColor = getColor(color: color2!)
            queueColor3.backgroundColor = getColor(color: color3!)
            queueColor4.backgroundColor = getColor(color: color4!)
        }
    }
    
    /// Ends game
    func endGame() {
        messageLabel.text = "You win"
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
            result = #colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1)
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
    }
    
    /// Initializes attributes from server
    func initializeAttributes() {
        // PLACEHOLDER DATA FOR TESTS
        queueList.append(["blue", "red", "yellow", "brown", "cyan"])
    }
    
    /// Loads default elements in AR
    func loadReality() {
        // Assign entities and model entities
        leftBox = experienceScene.leftBox!
        rightBox = experienceScene.rightBox!
        
        // Anchor entities
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
    
    /// Push one color in queue
    func pushQueueColor() {
        currentQueue.remove(at: 0)
        drawQueue()
    }

    /// Start collision detection system for current floating object
    func startCollisions() {
        //Subscribe scene to collision events
//        arView.scene.subscribe(
//            to: CollisionEvents.Began.self,
//            on: upBall
//        ) { event in
//            self.signalUp()
//        }.store(in: &collisionEventStreams)
    }
    
    /// Starts game
    func startGame() {
        if !bodyAnchorExists {
            // Body doesn't yet exist
            messageLabel.text = "No person detected"
        } else {
            // Draw queue
            currentQueue = queueList[0]
            drawQueue()
            
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
                let leftFootPos = simd_make_float3(skeleton.jointModelTransforms[4].columns.3)
                let rightFootPos = simd_make_float3(skeleton.jointModelTransforms[9].columns.3)
                let rootPos = simd_make_float3(skeleton.jointModelTransforms[0].columns.3)
                bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
                
                // Update position and orientation of elements
                characterAnchor.position = bodyPosition!
                characterAnchor.orientation = bodyOrientation
                
                leftBox.position = leftFootPos
                rightBox.position = rightFootPos
                
                // Attach character to anchor
                if let character = character, character.parent == nil {
                    characterAnchor.addChild(character)
                }
            }
        }
    }
    
}
