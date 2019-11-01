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

    // Unwind segue for return to menu
    @IBAction func unwindToMenu(_ unwindSegue: UIStoryboardSegue) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    

}
