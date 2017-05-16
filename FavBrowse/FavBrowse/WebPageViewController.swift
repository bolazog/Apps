//
//  ViewController.swift
//  FavBrowse
//
//  Created by Nick on 16.05.17.
//  Copyright © 2017 Mount. All rights reserved.
//

import UIKit
import WebKit
import CoreData

class WebPageViewController: UIViewController, WKNavigationDelegate {
  
  var webView: WKWebView!
  var progressView: UIProgressView!
  var webSites = [NSManagedObject]()
  
  override func loadView() {
    webView = WKWebView()
    webView.navigationDelegate = self
    view = webView
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(true)
    
    guard let delegate = UIApplication.shared.delegate as? AppDelegate else { return }
    
    let managedContext = delegate.persistentContainer.viewContext
    let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Website")
    
    do {
      webSites = try managedContext.fetch(fetchRequest)
    } catch let error as NSError {
      print("Could not fetch websites: \(error)")
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupToolbar()
    setupButtons()
    loadPage(action: UIAlertAction())
    
    webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
  }
  
  // MARK: Load Methods

  func loadPage(action: UIAlertAction) {
    let url = URL(string: action.title ?? "https://www.google.com")!
    
    webView.load(URLRequest(url: url))
    webView.allowsBackForwardNavigationGestures = true
  }
  
  // MARK: Actions Handlers
  
  func addTapped() {
    let ac = UIAlertController(title: "Add a website", message: "Type your site with domen in the field below", preferredStyle: .alert)
    ac.addTextField()
    
    ac.addAction(UIAlertAction(title: "Cancel", style: .default))
    ac.addAction(UIAlertAction(title: "Add", style: .default) { [unowned self] action in
      guard let textField = ac.textFields?.first, let textToSave = textField.text else { return }
      
      self.save(title: "https://www.\(textToSave)")
    })
    
    present(ac, animated: true)
  }
  
  func favTapped() {
    let ac = UIAlertController(title: "Favorites", message: nil, preferredStyle: .actionSheet)
    
    for site in webSites {
      let title = site.value(forKeyPath: "title") as? String
      ac.addAction(UIAlertAction(title: title, style: .default, handler: loadPage))
    }
    
    ac.addAction(UIAlertAction(title: "Close", style: .destructive))
    
    present(ac, animated: true)
  }
  
  // MARK: CoreData Stuff
  
  func save(title: String) {
    guard let delegate = UIApplication.shared.delegate as? AppDelegate else { return }
    
    let managedContext = delegate.persistentContainer.viewContext
    let entity = NSEntityDescription.entity(forEntityName: "Website", in: managedContext)!
    
    let website = NSManagedObject(entity: entity, insertInto: managedContext)
    website.setValue(title, forKeyPath: "title")
    
    do {
      try managedContext.save()
      webSites.append(website)
    } catch let error as NSError {
      print("Could not save website: \(error)")
    }
    
  }
  
  // MARK: Setup Methods
  
  func setupButtons() {
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))
    navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .bookmarks, target: self, action: #selector(favTapped))
  }
  
  func setupToolbar() {
    progressView = UIProgressView(progressViewStyle: .default)
    progressView.sizeToFit()
    
    let progressButton = UIBarButtonItem(customView: progressView)
    
    let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    let refresh = UIBarButtonItem(barButtonSystemItem: .refresh, target: webView, action: #selector(webView.reload))
    
    toolbarItems = [progressButton, spacer, refresh]
    navigationController?.isToolbarHidden = false
  }
  
  // MARK: Delegate Methods
  
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    title = webView.title
    
    UIView.animate(withDuration: 0.5, animations: {
      self.progressView.alpha = 0.0
    })
  }
  
  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    if keyPath == "estimatedProgress" {
      UIView.animate(withDuration: 0.2, animations: {
        self.progressView.alpha = 1.0
      })
      progressView.progress = Float(webView.estimatedProgress)
    }
  }
  
}
