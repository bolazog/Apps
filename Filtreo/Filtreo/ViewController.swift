//
//  ViewController.swift
//  Filtreo
//
//  Created by Nick on 18.05.17.
//  Copyright © 2017 Mount. All rights reserved.
//

import UIKit
import CoreImage

class ViewController: UIViewController, UINavigationControllerDelegate {

  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var intensity: UISlider!
  @IBOutlet weak var keyTitle: UILabel!
  
  var currentImage: UIImage!
  var context: CIContext!
  var currentFilter: CIFilter!
  
  @IBAction func changeFilterTapped(_ sender: Any) {
    let ac = UIAlertController(title: "Choose filter", message: nil, preferredStyle: .actionSheet)
    ac.addAction(UIAlertAction(title: "CIBumpDistortion", style: .default, handler: setFilter))
    ac.addAction(UIAlertAction(title: "CIGaussianBlur", style: .default, handler: setFilter))
    ac.addAction(UIAlertAction(title: "CIPixellate", style: .default, handler: setFilter))
    ac.addAction(UIAlertAction(title: "CISepiaTone", style: .default, handler: setFilter))
    ac.addAction(UIAlertAction(title: "CITwirlDistortion", style: .default, handler: setFilter))
    ac.addAction(UIAlertAction(title: "CIUnsharpMask", style: .default, handler: setFilter))
    ac.addAction(UIAlertAction(title: "CIVignette", style: .default, handler: setFilter))
    ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    
    present(ac, animated: true)
  }
  
  @IBAction func saveTapped(_ sender: Any) {
    guard let imageToSave = imageView.image else { return }
    
    UIImageWriteToSavedPhotosAlbum(imageToSave, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
  }
  
  @IBAction func intensityChanged(_ sender: Any) {
    applyProcessing()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    intensity.isEnabled = false
    
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(importPicture))
    
    context = CIContext()
    currentFilter = CIFilter(name: "CISepiaTone")
  }
  
  // MARK: Custom Methods
  
  func importPicture() {
    let picker = UIImagePickerController()
    picker.delegate = self
    picker.allowsEditing = true
    
    present(picker, animated: true)
  }
  
  func applyProcessing() {
    let keys = currentFilter.inputKeys
    
    if keys.contains(kCIInputIntensityKey) { currentFilter.setValue(intensity.value, forKey: kCIInputIntensityKey) }
    if keys.contains(kCIInputRadiusKey) {
      keyTitle.text = "Radius"
      currentFilter.setValue(intensity.value * 200, forKey: kCIInputRadiusKey)
    }
    
    if keys.contains(kCIInputScaleKey) {
      keyTitle.text = "Scale"
      currentFilter.setValue(intensity.value * 10, forKey: kCIInputScaleKey)
    }
    
    if keys.contains(kCIInputCenterKey) {
      keyTitle.text = "Center"
      currentFilter.setValue(CIVector(x: currentImage.size.width / 2, y: currentImage.size.height / 2), forKey: kCIInputCenterKey)
    }
    
    if let cgImage = context.createCGImage(currentFilter.outputImage!, from: currentFilter.outputImage!.extent) {
      let processedImage = UIImage(cgImage: cgImage)
      
      imageView.image = processedImage
    }
  }
  
  func setFilter(action: UIAlertAction) {
    guard currentImage != nil else { return }
    
    currentFilter = CIFilter(name: action.title!)
    
    let beginImage = CIImage(image: currentImage)
    currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
    
    
    applyProcessing()
  }
  
  func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
    if let error = error {
      // We recieved an error
      let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
      ac.addAction(UIAlertAction(title: "OK", style: .default))
      present(ac, animated: true)
    } else {
      let ac = UIAlertController(title: "Saved!", message: "Your edited image has been saved to your photos album!", preferredStyle: .alert)
      ac.addAction(UIAlertAction(title: "OK", style: .default))
      
      present(ac, animated: true)
    }
  }
}

extension ViewController: UIImagePickerControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    guard let image = info[UIImagePickerControllerEditedImage] as? UIImage else { return }
    
    dismiss(animated: true)
    currentImage = image
    
    let beginImage = CIImage(image: currentImage)
    currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
    
    intensity.isEnabled = true
    applyProcessing()
  }
  
}


