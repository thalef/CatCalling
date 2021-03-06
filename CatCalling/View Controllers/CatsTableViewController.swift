//
//  CatsTableViewController.swift
//  CatCalling
//
//  Created by Jen Person on 4/30/18.
//  Copyright © 2018 Google. All rights reserved.
//

import UIKit
import Foundation
import Firebase

var currentCat: Cat?

class CatsTableViewController: UIViewController {

  // MARK: Properties
  let addCat = "addCat"
  let settings = "showSettings"
  let catcell = "catcell"
  let backItem = UIBarButtonItem()
  var startCat: String?
  lazy var loginManager = LoginManager()
  lazy var refreshControl: UIRefreshControl = {
    let refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action:
      #selector(CatsTableViewController.handleRefresh(_:)),
                             for: UIControlEvents.valueChanged)
    return refreshControl
  }()
  
  // MARK: Outlets
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var actvityIndicator: UIActivityIndicatorView!
  
  override func viewDidLoad() {
      super.viewDidLoad()
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = 650
    backItem.title = "Cancel"
    navigationItem.backBarButtonItem = backItem
    tableView.addSubview(self.refreshControl)
  
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    initializeCats()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    startCat?.removeAll()
    isDynamicLink = false
  }
  
  func initializeCats() {
    removeData()
    actvityIndicator.startAnimating()
    CatManager.sharedInstance.downloadCats(startAt: startCat, startAfter: nil) {
      self.tableView.reloadData()
      self.actvityIndicator.stopAnimating()
      if self.refreshControl.isRefreshing {
        self.refreshControl.endRefreshing()
      }
    }
  }
  
  func removeData() {
    CatManager.sharedInstance.cats = []
    tableView.reloadData()
  }

  // show share sheet to share cat
  func share() {
    guard let cat = currentCat else {
      return
    }
    
    LinkManager.sharedInstance.createLink(propertyName: LinkManager.LinkTypes.cat.rawValue, propertyVal: cat.key!) { link, err in
      if let err = err {
        print(err)
        return
      }
      let activityViewController = UIActivityViewController(
        activityItems: ["Check out this cat I liked on CatCalling!", link],
        applicationActivities: nil)
      self.present(activityViewController, animated: true, completion: nil)
    }
  }
  
  func handleRefresh(_ refreshControl: UIRefreshControl) {
    isDynamicLink = false
    startCat = nil
    initializeCats()
    refreshControl.endRefreshing()
  }
  
  @IBAction func didTapAddCat(_ sender: Any) {
    // check that user is logged in before allowing them to add
    self.displayActionSheet(isUser: isUser)
  }
  
}

// MARK: Segue and action handling

extension CatsTableViewController {
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == settings {
      backItem.title = "Done"
    } else {
      backItem.title = "Cancel"
    }
  }
  
  func showSettings() {
    self.performSegue(withIdentifier: settings, sender: nil)
  }
  
  func displayActionSheet(isUser: Bool) {
    let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    let toggleAction = UIAlertAction(title: "Settings", style: .default) { action in
      self.showSettings()
    }
    alertController.addAction(toggleAction)
    if isUser == true {
      let logoutAction = UIAlertAction(title: "Log Out", style: .default) { action in
        LoginManager.sharedInstance.signOut()
      }
      let addCatAction = UIAlertAction(title: "Add Cat", style: .default) { action in
        self.performSegue(withIdentifier: self.addCat, sender: nil)
      }
      alertController.addAction(addCatAction)
      alertController.addAction(logoutAction)
    } else {
      let loginAction = UIAlertAction(title: "Log In to Add Photos", style: .default) { action in
        LoginManager.sharedInstance.signIn()
      }
      alertController.addAction(loginAction)
    }
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    alertController.addAction(cancelAction)
    self.navigationController?.present(alertController, animated: true, completion: nil)
  }
}


extension CatsTableViewController: UITableViewDelegate, UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return CatManager.sharedInstance.cats.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCell(withIdentifier: catcell, for: indexPath) as! CatsTableViewCell
    cell.cat = CatManager.sharedInstance.cats[indexPath.item]
    cell.layoutIfNeeded()
    return cell
  }
  
  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    if indexPath.row == CatManager.sharedInstance.cats.count-1 {
      guard let lastDoc = CatManager.sharedInstance.lastDoc else { return }
      isDynamicLink = false
      CatManager.sharedInstance.downloadCats(startAt: nil, startAfter: lastDoc) {        self.tableView.reloadData()
      }
    }
  }
  
}


