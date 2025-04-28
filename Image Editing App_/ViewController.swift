//
//  ViewController.swift
//  Image Editing App_
//
//  Created by
//

import UIKit
import CoreML
import UniformTypeIdentifiers

class ViewController: UIViewController {
    
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    let model = try! EditedImages_15(configuration: .init()).model
   // EditingImages_9copy_1(configuration: .init()).model
    let picker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func addButtonTapped(_sender : UIButton){
        setupPicker()
        imageView.backgroundColor = .black
    }
    
    func setupPicker() {
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [UTType.image.identifier]
        picker.allowsEditing = false
        present(picker, animated: true, completion: nil)
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            guard let ciImage = CIImage(image: image) else {return}
            let targetSize = CGSize(width: 512, height: 512)
            guard let pixelBuffer = createPixelBuffer(from: ciImage, targetSize: targetSize) else { return }
            let input = EditedImages_15Input(image: pixelBuffer)
            do {
                let output = try model.prediction(from: input)
                let featureNames = output.featureNames
                for featureName in featureNames {
                    if let featureValue = output.featureValue(for: featureName) {
                        if let imageBuffer = featureValue.imageBufferValue {
                            let ciImageOutput = CIImage(cvImageBuffer: imageBuffer)
                            imageView.image = UIImage(ciImage: ciImageOutput)
                        }
                    }
                }
            } catch {
                print("")
            }
            picker.dismiss(animated: true)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func createPixelBuffer(from ciImage: CIImage, targetSize: CGSize) -> CVPixelBuffer? {
        let scaleX = targetSize.width / ciImage.extent.width
        let scaleY = targetSize.height / ciImage.extent.height
        let scale = min(scaleX, scaleY)
        let resizedImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        let cropRect = CGRect(x: (resizedImage.extent.width - targetSize.width) / 2, y: (resizedImage.extent.height - targetSize.height) / 2, width: targetSize.width, height: targetSize.height)
        
        let croppedImage = resizedImage.cropped(to: cropRect)
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(targetSize.width), Int(targetSize.height), kCVPixelFormatType_32BGRA, attrs, &pixelBuffer)
        
        guard let buffer = pixelBuffer, status == kCVReturnSuccess else { return nil }
        
        let ciContext = CIContext()
        ciContext.render(croppedImage, to: buffer)
        
        return pixelBuffer
    }
}
