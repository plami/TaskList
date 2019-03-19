//
//  NotificationsTableViewCell.swift
//  TaskManager
//
//  Created by macbook on 18.03.19.
//  Copyright © 2019 macbook. All rights reserved.
//

import UIKit
import UserNotifications

class NotificationsTableViewCell: UITableViewCell {

    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var turnOnOffNotifications: UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    @IBAction func buttonOnOffNotifications(_ sender: UISwitch) {
        if turnOnOffNotifications.isOn {
            turnOnOffNotifications.setOn(false, animated:true)
        } else {
            turnOnOffNotifications.setOn(true, animated:true)
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
