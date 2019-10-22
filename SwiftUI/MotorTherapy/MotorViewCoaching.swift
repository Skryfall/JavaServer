//
//  MotorViewCoaching.swift
//  MotorTherapy
//
//  Created by Alejandro Ibarra on 10/11/19.
//  Copyright © 2019 Schlafenhase. All rights reserved.
//

import UIKit
import RealityKit
import ARKit

extension MotorView: ARCoachingOverlayViewDelegate {
    
    func addCoaching() {
        // Create a ARCoachingOverlayView object
        let coachingOverlay = ARCoachingOverlayView()
        
        // Make sure it rescales if the device orientation changes
        coachingOverlay.autoresizingMask = [
          .flexibleWidth, .flexibleHeight
        ]
        self.addSubview(coachingOverlay)
        
        // Set the Augmented Reality goal
        coachingOverlay.goal = .horizontalPlane
        
        // Set the ARSession
        coachingOverlay.session = self.session
        
        // Set the delegate for any callbacks
        coachingOverlay.delegate = self
    }
    
    // Example callback for the delegate object
    public func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        
    }
}
