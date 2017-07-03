//
//  CalloutButton.swift
//  Toilet Locator
//
//  Created by Spencer Gritton on 5/30/17.
//  Copyright © 2017 Spencer Gritton. All rights reserved.
//

import UIKit
import MapKit

class CalloutButton: UIButton {

    var internalName: String
    var internalPlacemark: MKPlacemark
    
    required init(name: String, placemark: MKPlacemark) {
        internalName = name
        internalPlacemark = placemark
        
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
