//
//  ViewController.swift
//  DogIdentifier
//
//  Created by Buse Karabıyık on 23.09.2023.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController {
    
    @IBOutlet weak var dogBreedLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var imageView: UIImageView!
    
    
    @IBOutlet weak var camera: UIBarButtonItem!
    
    @IBOutlet weak var photo: UIBarButtonItem!
    
    
    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: MyDogsImageClassifier(configuration: MLModelConfiguration()).model)
            let request = VNCoreMLRequest(model: model) { [weak self] request, error in
                self?.processObservations(for: request, error: error)
            }
            request.imageCropAndScaleOption = .centerCrop
            return request
        }catch {
            fatalError("Failed to create model: \(error)")
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.97, green: 0.94, blue: 0.90, alpha: 1.00)
    }
    
    
    //MARK: - pictures
    
    
    @IBAction func photoPressed(_ sender: Any) {
        
        let photoSourceAlert = UIAlertController()
        
        let choosePhoto = UIAlertAction(title: "Choose Photo", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .photoLibrary)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        
        photoSourceAlert.addAction(choosePhoto)
        photoSourceAlert.addAction(cancel)
        
        photoSourceAlert.popoverPresentationController?.barButtonItem = photo
        
        present(photoSourceAlert, animated: true)
        
    }
    
    
    @IBAction func cameraPressed(_ sender: Any) {
        
        let photoSourceAlert = UIAlertController()
        
        let takePhoto = UIAlertAction(title: "Take Photo", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .camera)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        photoSourceAlert.addAction(takePhoto)
        photoSourceAlert.addAction(cancel)
        
        photoSourceAlert.popoverPresentationController?.barButtonItem = camera
        
        present(photoSourceAlert, animated: true)
        
    }
    

    
    //MARK: - present photo picker
    
    func presentPhotoPicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        present(picker, animated: true)
    }
    
    //MARK: - performing Request
    
    func classify(image: UIImage) {
        dogBreedLabel.text = "Identifying..."
    
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        guard let ciImage = CIImage(image: image) else { fatalError("Unable to create \(CIImage.self) from \(image).") }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                try handler.perform([self.classificationRequest])
            } catch {
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
    }
    
    //MARK: - processing Clasification, Updating the UI
    
    func processObservations(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            if let results = request.results as? [VNClassificationObservation] {
                if results.isEmpty {
                    self.dogBreedLabel.text = "Nothing found :/"
                }else {
                    self.dogBreedLabel.text = String(results[0].identifier)
                }
            }else if let error = error {
                self.dogBreedLabel.text = "error: \(error.localizedDescription)"
                print("error: \(error.localizedDescription)")
            }
        }
    }
    
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        
        picker.dismiss(animated: true)
        
        let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as! UIImage
        
        imageView.image = image
       
        descriptionLabel.text = ""
        
        classify(image: image)
    }
}

// Helper function
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
    return input.rawValue
}
