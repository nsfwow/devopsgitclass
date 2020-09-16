//
//  PreviewView.swift
//  MachineLearningDemo
//
//  Created by Rafael Aguilera on 11/21/17.
//  Copyright © 2017 Rafael Aguilera. All rights reserved.
//

import UIKit
import AVFoundation

class PreviewView: UIView {
    
    private var maskLayer = [CAShapeLayer]()
    
    
    // MARK: AV capture properties
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        
        set {
            videoPreviewLayer.session = newValue
        }
    }
    
    override class var layerClass: AnyClass {
       