//
//  ViewController.swift
//  SecretSwift
//
//  Created by Nick on 15.04.17.
//  Copyright © 2017 Mount. All rights reserved.
//

import UIKit
import LocalAuthentication

class ViewController: UIViewController {

  @IBOutlet weak var authButton: UIButton!
  @IBOutlet weak var secret: UITextView!
  @IBAction func authenticateUser(_ sender: Any) {
    let context = LAContext()
    var error: NSError?
    
    if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
      let reason = "Identify yourself!"
      
      context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [unowned self] (success, authError) in
        DispatchQueue.main.async {
          if success {
            self.unlockSecretMessage()
          } else {
            // error
            let ac = UIAlertController(title: "Authentication failed", message: "Your fingerprint could not be verified; please try again.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(ac, animated: true)
          }
        }
      }
    } else {
      // no TouchID
      let ac = UIAlertController(title: "Touch ID not available", message: "Your device is not configured for Touch ID.", preferredStyle: .alert)
      ac.addAction(UIAlertAction(title: "OK", style: .default))
      self.present(ac, animated: true)
    }
    
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Nothing to see here"
    
    let notificationCenter = NotificationCenter.default
    notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: Notification.Name.UIKeyboardWillHide, object: nil)
    notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: Notification.Name.UIKeyboardWillChangeFrame, object: nil)
    notificationCenter.addObserver(self, selector: #selector(saveSecretMessage), name: Notification.Name.UIApplicationWillResignActive, object: nil)
  }
  
  func unlockSecretMessage() {
    authButton.isHidden = true
    secret.isHidden = false
    title = "Secret stuff here!"
    
    
    if let text = KeychainWrapper.standardKeychainAccess().string(forKey: "SecretMessage") {
      secret.text = text
    }
  }
  
  func saveSecretMessage() {
    if !secret.isHidden {
      _ = KeychainWrapper.standardKeychainAccess().setString(secret.text, forKey: "SecretMessage")
      secret.resignFirstResponder()
      secret.isHidden = true
      authButton.isHidden = false
      title = "Nothing to see here"
    }
  }
  
  func adjustForKeyboard(notification: Notification) {
    let userInfo = notification.userInfo!
    
    let keyboardScreenEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
    let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
    
    if notification.name == Notification.Name.UIKeyboardWillHide {
      secret.contentInset = UIEdgeInsets.zero
    } else {
      secret.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height, right: 0)
    }
    secret.scrollIndicatorInsets = secret.contentInset
    
    let selectedRange = secret.selectedRange
    secret.scrollRangeToVisible(selectedRange)
  }


}

