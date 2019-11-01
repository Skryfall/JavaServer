//
//  MessageLabel.swift
//  MotorTherapy
//
//  Created by Alejandro Ibarra on 10/9/19.
//  Copyright © 2019 Schlafenhase. All rights reserved.
//

import UIKit

@IBDesignable
class MessageLabel: UILabel {
        
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        super.drawText(in: rect.inset(by: insets))
    }
    
    
    func displayMessage(_ text: String, duration: TimeInterval,_ defaultText: String) {
        DispatchQueue.main.async {
            self.isHidden = false
            self.text = text
        }
        
        // Use tag to tell if the label has been updated.
        let tag = self.tag + 1
        self.tag = tag
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            // Do not hide if showMessage is called again before this block kicks in.
            if self.tag == tag {
                self.text = defaultText
            }
        }
    }
}
