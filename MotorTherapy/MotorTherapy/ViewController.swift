//
//  ViewController.swift
//  MotorTherapy
//
//  Created by Alejandro Ibarra on 10/9/19.
//  Copyright © 2019 Schlafenhase. All rights reserved.
//

import UIKit
import ARKit
import RealityKit

class ViewController: UIViewController {
    
    // MARK: - UI Elements
    
    @IBOutlet weak var onlineSwitch: UISwitch!
    @IBOutlet weak var toBalloonViewButton: UIButton!
    @IBOutlet weak var toFeetViewButton: UIButton!
    @IBOutlet weak var toFloatingViewButton: UIButton!
    @IBOutlet weak var toSpiderWebViewButton: UIButton!
    
    // MARK: - View Control
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? FloatingView {
            vc.isOnline = onlineSwitch.isOn
        } else if let vc = segue.destination as? FeetView {
            vc.isOnline = onlineSwitch.isOn
        } else if let vc = segue.destination as? BalloonView {
            vc.isOnline = onlineSwitch.isOn
        } else if let vc = segue.destination as? SpiderView {
            vc.isOnline = onlineSwitch.isOn
        }
    }

    // Unwind segue for return to menu
    @IBAction func unwindToMenu(_ unwindSegue: UIStoryboardSegue) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    

}
