//
//  ViewController.swift
//  PythagAR
//
//  Created by Andrea Gagliano on 10/1/17.
//  Copyright © 2017 Andrea Gagliano. All rights reserved.
//
//  Adapted from tutorial: https://virtualrealitypop.com/ios-11-tutorial-how-to-measure-objects-with-arkit-743d2ec78afc
//

import UIKit
import ARKit
import SceneKit

//Conform our ViewController to ARSCNViewDelegate
class ViewController: UIViewController, ARSCNViewDelegate {
    var nodes: [SphereNode] = []
    
    //Create a lazy sceneView variable to store ARSCNView instance
    lazy var sceneView: ARSCNView = {
        let view =  ARSCNView(frame: CGRect.zero)
        view.delegate = self
        return view
    }()
    
    //Create a label to display status information
    lazy var infoLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.title1)
        label.textAlignment = .center
        label.backgroundColor = .white
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Add sceneView to our host view
        view.addSubview(sceneView)
        //Add the label to the host view
        view.addSubview(infoLabel)
        //Init UITapGestureRecognizer and add it to our scene
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapRecognizer.numberOfTapsRequired = 1
        sceneView.addGestureRecognizer(tapRecognizer)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //Resize sceneView
        sceneView.frame = view.bounds
        //Update the label position
        infoLabel.frame = CGRect(x: 0, y:16, width: view.bounds.width, height: 64)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //Start ARKit session
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    //MARK: ARSCNViewDelegate
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
       //Implement protocol function to display status changes
        var status = "Loading..."
        switch camera.trackingState {
        case ARCamera.TrackingState.notAvailable:
            status = "Not available"
        case ARCamera.TrackingState.limited(_):
            status = "Analyzing..."
        case ARCamera.TrackingState.normal:
            status = "Ready"
        }
        infoLabel.text = status
    }
    
    //MARK: Gesture handlers
    @objc func handleTap(sender: UITapGestureRecognizer) {
        //Handle a tap on screen and get tap location in view's coordinates system
        let tapLocation = sender.location(in: sceneView)
        //Perform a hit test against feature points found by ARKit. Here we're searching for a point in 3D space corresponding to a 2D point in the view. This is where ARKit magic happens. As a result it returns a list of ARHitTestResults
        let hitTestResults = sceneView.hitTest(tapLocation, types: .featurePoint)
        if let result = hitTestResults.first {
            //Get 3D point coordinates from an ARHitTestResult
            let position = SCNVector3.positionFrom(matrix: result.worldTransform)
            //Create a SphereNode with found coordinates (look at full source code for more info)
            let sphere = SphereNode(position: position)
            //Add the sphere to our scene
            sceneView.scene.rootNode.addChildNode(sphere)
            let lastNode = nodes.last
            nodes.append(sphere)
            if lastNode != nil {
                //Calculate distance between two coordinates
                let distance = lastNode!.position.distance(to: sphere.position)
                infoLabel.text = String(format: "Distance: %.2f meters", distance)
            }
        }
    }
}

extension SCNVector3 {
    func distance(to destination: SCNVector3) -> CGFloat {
        let dx = destination.x - x
        let dy = destination.y - y
        let dz = destination.z - z
        return CGFloat(sqrt(dx*dx + dy*dy + dz*dz))
    }
    
    static func positionFrom(matrix: matrix_float4x4) -> SCNVector3 {
        let column = matrix.columns.3
        return SCNVector3(column.x, column.y, column.z)
    }
}

