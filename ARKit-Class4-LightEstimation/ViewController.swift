//
//  ViewController.swift
//  ARKit-Class4-LightEstimation
//
//  Created by apple on 11/05/19.
//  Copyright © 2019 appsmall. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var ambientIntensityLabel: UILabel!
    @IBOutlet weak var ambientIntensitySlider: UISlider!
    @IBOutlet weak var ambientColorTemp: UILabel!
    @IBOutlet weak var ambientColorTempSlider: UISlider!
    @IBOutlet weak var lightEstimationLabel: UILabel!
    @IBOutlet weak var lightEstimationSwitch: UISwitch!
    @IBOutlet weak var ambientIntensityStackView: UIStackView!
    @IBOutlet weak var lightEstimationStackView: UIStackView!
    @IBOutlet weak var mainStackView: UIStackView!
    
    var lightNodes = [SCNNode]()
    
    var detectedHorizontalPlane = false {
        didSet {
            DispatchQueue.main.async {
                self.mainStackView.isHidden = !self.detectedHorizontalPlane
                self.instructionLabel.isHidden = self.detectedHorizontalPlane
                self.lightEstimationStackView.isHidden = !self.detectedHorizontalPlane
            }
        }
    }
    
    
    // MARK:- VIEW CONTROLLER LIFE CYCLE METHODS
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpSceneView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    func setUpSceneView() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        sceneView.delegate = self
    }
    
    func getSphereNode(withPosition position: SCNVector3) -> SCNNode {
        let sphere = SCNSphere(radius: 0.1)
        
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = position
        sphereNode.position.y += Float(sphere.radius) + 1
        
        return sphereNode
    }
    
    func addLightNodeTo(_ node: SCNNode) {
        let lightNode = getLightNode()
        node.addChildNode(lightNode)
        lightNodes.append(lightNode)
    }
    
    func getLightNode() -> SCNNode {
        let light = SCNLight()
        light.type = .omni
        light.intensity = 0
        light.temperature = 0
        
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(-1, 0, 0)
        
        return lightNode
    }
    
    func updateLightNodesLightEstimation() {
        DispatchQueue.main.async {
            guard self.lightEstimationSwitch.isOn, let lightEstimate = self.sceneView.session.currentFrame?.lightEstimate else {
                return
            }
            
            let ambientIntensity = lightEstimate.ambientIntensity
            let ambientColorTemperature = lightEstimate.ambientColorTemperature
            
            for lightNode in self.lightNodes {
                guard let light = lightNode.light else { continue }
                light.intensity = ambientIntensity
                light.temperature = ambientColorTemperature
            }
        }
    }

    // MARK:- IBACTIONS
    @IBAction func ambientIntensitySliderPressed(_ sender: UISlider) {
        DispatchQueue.main.async {
            let ambientIntensity = sender.value
            self.ambientIntensityLabel.text = "Ambient Intensity: \(ambientIntensity)"
            
            guard !self.lightEstimationSwitch.isOn else { return }
            for lightNode in self.lightNodes {
                guard let light = lightNode.light else { continue }
                light.intensity = CGFloat(ambientIntensity)
            }
        }
    }
    
    @IBAction func ambientColorTempPressed(_ sender: UISlider) {
        DispatchQueue.main.async {
            let ambientColorTemperature = sender.value
            self.ambientColorTemp.text = "Ambient Color Temperature: \(ambientColorTemperature)"
            
            guard !self.lightEstimationSwitch.isOn else { return }
            for lightNode in self.lightNodes {
                guard let light = lightNode.light else { continue }
                light.temperature = CGFloat(ambientColorTemperature)
            }
        }
    }
    
    @IBAction func lightEstimationSwitchPressed(_ sender: UISwitch) {
        ambientIntensitySliderPressed(ambientIntensitySlider)
        ambientColorTempPressed(ambientColorTempSlider)
    }
}


// MARK:- ARSCNVIEW DELEGATE METHODS
extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        let planeAnchorCenter = SCNVector3(planeAnchor.center)
        
        let sphereNode = getSphereNode(withPosition: planeAnchorCenter)
        addLightNodeTo(sphereNode)
        node.addChildNode(sphereNode)
        detectedHorizontalPlane = true
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        updateLightNodesLightEstimation()
    }
    
}
