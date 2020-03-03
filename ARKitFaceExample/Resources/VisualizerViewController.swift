//
//  VisualizerViewController.swift
//  ARKitFaceExample
//
//  Created by Andrew Che on 2/29/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class VisualizerViewController: UIViewController {
    
    var url: URL?

    @IBAction func onCloseButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.modalPresentationStyle = UIModalPresentationStyle.formSheet
        
        
        let visualizer = VisualizerLauncher()
        visualizer.showVideoPlayer(url: url!)

    }

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}