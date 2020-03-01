/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 Displays coordinate axes visualizing the tracked face pose (and eyes in iOS 12).
 */

import ARKit
import SceneKit
import Charts

class TransformVisualization: NSObject, VirtualContentController {
    var contentNode: SCNNode?
    
    // Load multiple copies of the axis origin visualization for the transforms this class visualizes.
    lazy var rightEyeNode = SCNReferenceNode(named: "coordinateOrigin")
    lazy var leftEyeNode = SCNReferenceNode(named: "coordinateOrigin")
    
    var leftEyeArray: Array<Float> = Array()
    var rightEyeArray: Array<Float> = Array()
    var lookAtArray: Array<Float> = Array()
    var timeArray: Array<Int> = Array()
    var faceArray: Array<Float> = Array()
    var gain: Array<Float> = Array()
    var count = 0
    
    var testcomplete = false
    
    func setChartValues(_ count: Int = 500) -> LineChartData {
        let values = (0..<count).map { (i) -> ChartDataEntry in
            let val = faceArray[i]
            return ChartDataEntry(x: Double(i), y: Double(val))
        }
        let set1 = LineChartDataSet(entries: values, label: "DataSet 1")
        let data = LineChartData(dataSet: set1)
        
        return data
    }
    
    /// - Tag: ARNodeTracking
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        // This class adds AR content only for face anchors.
        guard anchor is ARFaceAnchor else { return nil }
        
        // Load an asset from the app bundle to provide visual content for the anchor.
        contentNode = SCNReferenceNode(named: "coordinateOrigin")
        
        // Add content for eye tracking in iOS 12.
        self.addEyeTransformNodes()
        
        // Provide the node to ARKit for keeping in sync with the face anchor.
        return contentNode
    }
    
    //    func processData(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
    //    guard #available(iOS 12.0, *), let faceAnchor = anchor as? ARFaceAnchor
    //        else { return }
    //
    //
    //    }
    
    func reset() {
        leftEyeArray.removeAll()
        rightEyeArray.removeAll()
        lookAtArray.removeAll()
        timeArray.removeAll()
        faceArray.removeAll()
        gain.removeAll()
        count = 0
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor, start:Bool) {
        guard #available(iOS 12.0, *), let faceAnchor = anchor as? ARFaceAnchor
            else { return }
        
        rightEyeNode.simdTransform = faceAnchor.rightEyeTransform
        leftEyeNode.simdTransform = faceAnchor.leftEyeTransform
        
        if (start) {
            if (count == 0) {
                print("STARTING DATA COLLECTION")
                testcomplete = false
            }
            
            let leftEyeX = leftEyeNode.simdTransform.columns.3.x
            let rightEyeX = rightEyeNode.simdTransform.columns.3.x
            
            let x = faceAnchor.lookAtPoint.x
            let timestamp = count
            let facecoordinate = faceAnchor.transform.columns.2.x
            leftEyeArray.append(leftEyeX)
            rightEyeArray.append(rightEyeX)
            lookAtArray.append(x)
            timeArray.append(timestamp)
            faceArray.append(facecoordinate)
            gain.append(facecoordinate + x)
            
            count = count + 1
            if (count == 500) {
                //write to csv file
                print("\nLeft eye array")
                print(leftEyeArray)
                print("\nRight eye array")
                print(rightEyeArray)
                print("\nLook at point array")
                print(lookAtArray)
                print("\nTime array")
                print(timeArray)
                print("\nFace array")
                print(faceArray)
                print("\nGain array")
                print(gain)
                
                print("min gain: ")
                print(gain.min())
                
                print("max gain: ")
                print(gain.max())
                testcomplete = true
//                reset()
            }
            
        }
    }
    
    func isTestComplete() -> Bool {
        return testcomplete
    }
    
    func addEyeTransformNodes() {
        guard #available(iOS 12.0, *), let anchorNode = contentNode else { return }
        
        // Scale down the coordinate axis visualizations for eyes.
        rightEyeNode.simdPivot = float4x4(diagonal: float4(3, 3, 3, 1))
        leftEyeNode.simdPivot = float4x4(diagonal: float4(3, 3, 3, 1))
        
        anchorNode.addChildNode(rightEyeNode)
        anchorNode.addChildNode(leftEyeNode)
    }
    
}
