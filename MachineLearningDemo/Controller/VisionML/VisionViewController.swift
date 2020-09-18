
//
//  VisionViewController.swift
//  MachineLearningDemo
//
//  Created by Rafael Aguilera on 11/21/17.
//  Copyright © 2017 Rafael Aguilera. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class VisionViewController: UIViewController {
    
    @IBOutlet weak var objectTextView: UILabel!
    @IBOutlet weak var previewView: PreviewView!
    
    // Live Camera Properties
    let captureSession = AVCaptureSession()
    var captureDevice:AVCaptureDevice!
    var devicePosition: AVCaptureDevice.Position = .back
    
    var requests = [VNRequest]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupVision()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepareCamera()
    }
    
    @IBAction func didTapPreviousDemo(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: {
        
        })
    }
    
    func setupVision() {
        let rectangleDetectionRequest = VNDetectRectanglesRequest(completionHandler: handleRectangles)
        rectangleDetectionRequest.minimumSize = 0.1
        rectangleDetectionRequest.maximumObservations = 1
        
        self.requests = [rectangleDetectionRequest]
    }
    
    func handleRectangles (request:VNRequest, error:Error?) {
        
    }
    
    
    
}
