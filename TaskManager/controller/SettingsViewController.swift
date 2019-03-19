//
//  SettingsViewController.swift
//  TaskManager
//
//  Created by macbook on 18.03.19.
//  Copyright © 2019 macbook. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.registerTableViewCell()
        
        self.navigationItem.leftBarButtonItem =
            UIBarButtonItem (title: "Back",
                             style: .plain,
                             target: self,
                             action: #selector(goBack))
    }
    
    @objc func goBack() {
        self.dismiss(animated: true, completion: nil)
    }
}

//MARK: TableViewDelegates
extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "notificationsCell", for: indexPath) as! NotificationsTableViewCell
        cell.selectionStyle = .none
        cell.labelTitle?.text = Constants.TurnONOFFNotifications.message
        
        return cell
    }
    
    func registerTableViewCell() {
        let nib = UINib(nibName: "NotificationsTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "notificationsCell")
    }
}
