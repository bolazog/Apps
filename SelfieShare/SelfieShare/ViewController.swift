//
//  ViewController.swift
//  SelfieShare
//
//  Created by Nick on 20.04.17.
//  Copyright © 2017 Mount. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  var images = [UIImage]()
  var mcSession: MCSession!
  var peerID: MCPeerID!
  var mcAdvertiserAssistant: MCAdvertiserAssistant!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    title = "Selfie Share"
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(importPicture))
    navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showConnectionPrompt))
    
    peerID = MCPeerID(displayName: UIDevice.current.name)
    mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
    mcSession.delegate = self
  }
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return images.count
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageView", for: indexPath)
    
    if let imageView = cell.viewWithTag(1000) as? UIImageView {
      imageView.image = images[indexPath.item]
    }
    
    return cell
  }
  
  // UIImagePicker Methods
  
  func importPicture() {
    let picker = UIImagePickerController()
    picker.delegate = self
    picker.allowsEditing = true
    
    present(picker, animated: true)
  }
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    guard let image = info[UIImagePickerControllerEditedImage] as? UIImage else { return }
    
    dismiss(animated: true)
    
    images.insert(image, at: 0)
    collectionView?.reloadData()
    
    if mcSession.connectedPeers.count > 0 {
      if let imageData = UIImagePNGRepresentation(image) {
        do {
          try mcSession.send(imageData, toPeers: mcSession.connectedPeers, with: .reliable)
        } catch {
          let ac = UIAlertController(title: "Send Error", message: nil, preferredStyle: .alert)
          ac.addAction(UIAlertAction(title: "OK", style: .default))
          
          present(ac, animated: true)
        }
      }
    }
  }
  
  // Multipeer Methods
  
  func showConnectionPrompt() {
    let ac = UIAlertController(title: "Connect ot others", message: nil, preferredStyle: .actionSheet)
    ac.addAction(UIAlertAction(title: "Host a session", style: .default, handler: startHosting))
    ac.addAction(UIAlertAction(title: "Join a session", style: .default, handler: joinSession))
    ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    
    present(ac, animated: true)
  }
  
  func startHosting(action: UIAlertAction) {
    mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "mnt-sfshare", discoveryInfo: nil, session: mcSession)
    mcAdvertiserAssistant.start()
  }
  
  func joinSession(action: UIAlertAction) {
    let mcBrowser = MCBrowserViewController(serviceType: "mnt-sfshare", session: mcSession)
    mcBrowser.delegate = self
    
    present(mcBrowser, animated: true)
  }
}

extension ViewController: MCSessionDelegate, MCBrowserViewControllerDelegate {
  func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
    if let image = UIImage(data: data) {
      DispatchQueue.main.async { [unowned self] in
        self.images.insert(image, at: 0)
        self.collectionView?.reloadData()
      }
    }
  }
  
  func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
    switch state {
    case .connected:
      print("Connected: \(peerID.displayName)")
    case .connecting:
      print("Connecting: \(peerID.displayName)")
    case .notConnected:
      print("Not Connected: \(peerID.displayName)")
    }
  }
  
  // Optional
  
  func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
    dismiss(animated: true)
  }
  
  func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
    dismiss(animated: true)
  }
  
  func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    
  }
  
  func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    
  }
  
  func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
    
  }

}

