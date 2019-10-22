//
//  ViewController.swift
//  MotorTherapy
//
//  Created by Alejandro Ibarra on 10/9/19.
//  Copyright © 2019 Schlafenhase. All rights reserved.
//

import UIKit
import RealityKit
import ARKit
import Combine

class ViewController: UIViewController, ARSessionDelegate {

    @IBOutlet var arView: ARView!
    @IBOutlet weak var messageLabel: MessageLabel!
    
    // The 3D character to display.
    var character: BodyTrackedEntity?
    let characterOffset: SIMD3<Float> = [0, 0, 0] // Offset robot position
    let characterAnchor = AnchorEntity()
    
    // A tracked raycast which is used to place the character accurately
    // in the scene wherever the user taps.
    var placementRaycast: ARTrackedRaycast?
    var tapPlacementAnchor: AnchorEntity?
    
    // Reality Composer experience
    var experienceAnchor = Experience.Scene()
    
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
                self.character = character
                cancellable?.cancel()
            } else {
                print("Error: Unable to load model as BodyTrackedEntity")
            }
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        experienceAnchor = try! Experience.loadScene()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        arView.session.delegate = self
        
        // If the iOS device doesn't support body tracking, raise a developer error.
        guard ARBodyTrackingConfiguration.isSupported else {
            fatalError("This feature is only supported on devices with an A12 chip")
        }

        // Run a body tracking configration.
        let configuration = ARBodyTrackingConfiguration()
        arView.session.run(configuration)
        
        loadRobot()
    
        arView.scene.addAnchor(characterAnchor)
        
        
        guard let anchor = try? Experience.loadScene() else { return }
        arView.scene.anchors.append(anchor)
        
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        let bodyAnchor = characterAnchor
            
        // Update the position of the character anchor's position.
        let bodyPosition = simd_make_float3(bodyAnchor.transform.matrix.columns.3)
        characterAnchor.position = bodyPosition
            //+ characterOffset
         
        // Also copy over the rotation of the body anchor, because the skeleton's pose
        // in the world is relative to the body anchor's rotation.
        characterAnchor.orientation = bodyAnchor.transform.rotation
        //characterAnchor.orientation = Transform(matrix: bodyAnchor.transform).rotation

        if let character = character, character.parent == nil {
            // Attach the character to its anchor as soon as
            // 1. the body anchor was detected and
            // 2. the character was loaded.
            characterAnchor.addChild(character)
        }
        
//        for anchor in anchors {
//            guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }
//
//            // Update the position of the character anchor's position.
//            let bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
//            characterAnchor.position = bodyPosition
//                //+ characterOffset
//
//            // Also copy over the rotation of the body anchor, because the skeleton's pose
//            // in the world is relative to the body anchor's rotation.
//            characterAnchor.orientation = Transform(matrix: bodyAnchor.transform).rotation
//
//            if let character = character, character.parent == nil {
//                // Attach the character to its anchor as soon as
//                // 1. the body anchor was detected and
//                // 2. the character was loaded.
//                characterAnchor.addChild(character)
//            }
//        }
    }
}
