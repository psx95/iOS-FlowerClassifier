//
//  ViewController.swift
//  FlowerIdentify
//
//  Created by Pranav Sharma on 09/03/19.
//  Copyright © 2019 Pranav Sharma. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!    
    @IBOutlet weak var descriptionLabel: UILabel!
    
    let imagePicker = UIImagePickerController()
    let wikiApiUrl = "https://en.wikipedia.org/w/api.php"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .camera
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.image = userPickedImage
            
            guard let ciImage = CIImage(image: userPickedImage) else {
                fatalError("Could not convert UI Image to CIImage")
            }
            detect(ciImage: ciImage)
        } else {
            print("Some error occured")
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    private func detect (ciImage: CIImage) {
        do {
            // Create the model that will be used for classifying the flowers
            let model = try VNCoreMLModel(for: FlowerClassifier().model)
            
            // create a request that uses the model created above
            let request = VNCoreMLRequest(model: model) { (vnRequest, error) in
                guard let results = vnRequest.results as? [VNClassificationObservation] else {
                    fatalError("Could not convert Results to classification")
                }
                
                if let firstResult = results.first {
                    print(firstResult.identifier)
                    self.navigationItem.title = firstResult.identifier.capitalized
                    self.getFlowerInfo(forName: firstResult.identifier)
                }
                
                
            }
            
            // Process the request created above
            let handler = VNImageRequestHandler(ciImage: ciImage)
            do {
                try handler.perform([request])
            } catch {
                print(error)
            }
        } catch {
            print("Some error occured")
        }
    }
    
    private func getFlowerInfo(forName flower: String){
        let params: [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flower,
            "indexpageids" : "",
            "redirects" : "1",
            ]
        
        Alamofire.request(wikiApiUrl, method: .get, parameters: params).responseJSON { (response) in
            if response.result.isSuccess {
                print("Api request successfull")
                let jsonResponse : JSON = JSON(response.result.value!)
                print("Response is \(jsonResponse)")
                let pageId = jsonResponse["query"]["pageids"][0].stringValue
                print ("Page id is \(pageId)")
                let description: String = jsonResponse["query"]["pages"][pageId]["extract"].stringValue
                self.displayInfo(info: description)
            } else if response.result.isFailure {
                self.displayInfo(info: "Some error occured while fetching info")
            }
        }
    }
    
    private func displayInfo (info: String) {
        print ("Final Extract is \(info)")
        descriptionLabel.text = info
    }


    @IBAction func onCameraButtonClicked(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
}
