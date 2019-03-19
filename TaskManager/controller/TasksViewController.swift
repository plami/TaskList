//
//  ViewController.swift
//  TaskManager
//
//  Created by macbook on 14.03.19.
//  Copyright © 2019 macbook. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

class TasksViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    //MARK - Public Properties
    
    var moc: NSManagedObjectContext? {
        didSet {
            if let moc = moc {
                taskService = TaskService(moc: moc)
            }
        }
    }
    
    //MARK - Private Properties
    
    private var taskService: TaskService?
    private var taskList = [Task]()
    private var doneTaskList = [Task]()
    private var taskToUpdate: Task?
    private var counterDoneTasks: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerTableViewCell()
        loadTasks()
        
       NotificationCenter.default.addObserver(self, selector: #selector(observerSelector(_:)), name: Notification.Name.NSManagedObjectContextObjectsDidChange, object: nil)
        
        /* //Testing local notifications
        let content = UNMutableNotificationContent()
        content.title = "Title"
        content.body = "Body"
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: true)
        
        let request = UNNotificationRequest(identifier: "TestIdentifier", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        */
    }
    
    @objc func observerSelector(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }

        if (userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>) != nil {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    //MARK: Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "addTask" {
            prepareSegueForAddTaskViewController(segue: segue)
        }
        
        if segue.identifier == "goToSettings" {
            prepareSegueForSettingsViewController(segue: segue)
        }
    }
    
    private func prepareSegueForAddTaskViewController(segue: UIStoryboardSegue) {
        guard let nav = segue.destination as? UINavigationController else {
            fatalError("NavigationController not found")
        }
        
        guard let addTaskVC = nav.viewControllers.first as? AddUpdateTaskViewController else {
            fatalError("AddUpdateTaskViewController not found")
        }
        addTaskVC.moc = moc
        addTaskVC.buttonSaveUpdate = Constants.ButtonTitles.save
    }
    
    private func prepareSegueForSettingsViewController(segue: UIStoryboardSegue) {
        guard let nav = segue.destination as? UINavigationController else {
            fatalError("NavigationController not found")
        }
        
        guard let settingsTaskVC = nav.viewControllers.first as? SettingsViewController else {
            fatalError("SettingsViewController not found")
        }
    }
    
    private func loadTasks() {
        if let tasks = taskService?.getPendingTasks() {
            taskList = tasks
        }
        if let doneTasks = taskService?.getDoneTasks() {
            doneTaskList = doneTasks
        }
    }
}

//MARK: TableViewDelegates
extension TasksViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return doneTaskList.count
        }
        return taskList.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        switch(section) {
            
        case 0:return Constants.TableViewHeaders.PendingTasks
        case 1:return Constants.TableViewHeaders.DoneTasks
            
        default :return ""
            
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        let done = UIContextualAction(style: .normal, title: Constants.ButtonTitles.done, handler: { (ac:UIContextualAction, view:UIView, success:@escaping (Bool) -> Void) in

            self.taskToUpdate = self.taskList[indexPath.row]
            
            self.taskService?.moveFromPendingToDoneTask(currentTask: self.taskToUpdate!, withStatus: true, forCategory: self.taskList[indexPath.row].categoryColour ?? "")
            self.taskList.remove(at: indexPath.row)
            self.doneTaskList.append(self.taskToUpdate!)
        })
        done.backgroundColor = UIColor.lightGray
        
        let delete = UIContextualAction(style: .normal, title: Constants.ButtonTitles.delete, handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            if indexPath.section == 0 {
                self.taskService?.deletePendingTask(task: self.taskList[indexPath.row])
                self.taskList.remove(at: indexPath.row)
            }
            if indexPath.section == 1 {
                self.taskService?.deleteDoneTask(task: self.doneTaskList[indexPath.row])
                self.doneTaskList.remove(at: indexPath.row)
            }
            tableView.deleteRows(at: [indexPath], with: .fade)
        })
        delete.backgroundColor = UIColor.red
        
        if indexPath.section == 0 {
           return UISwipeActionsConfiguration(actions: [done,delete])
        } else {
            return UISwipeActionsConfiguration(actions: [delete])
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "taskCell", for: indexPath) as! TaskTableViewCell
        
        if indexPath.section == 0 {
            cell.textLabel?.text = taskList[indexPath.row].title
            cell.detailTextLabel?.text = taskList[indexPath.row].completionDate
            cell.backgroundColor = UIColor(hexString: taskList[indexPath.row].categoryColour ?? "")
        }
        if indexPath.section == 1 {
            cell.textLabel?.text = doneTaskList[indexPath.row].title
            cell.detailTextLabel?.text = doneTaskList[indexPath.row].completionDate
            cell.backgroundColor = UIColor(hexString: doneTaskList[indexPath.row].categoryColour ?? "")
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let detailsViewController = storyBoard.instantiateViewController(withIdentifier: "AddUpdateTaskViewController") as! AddUpdateTaskViewController
        if indexPath.section == 0 {
            detailsViewController.selectedTask = taskList[indexPath.row]
            detailsViewController.isDoneTask = false
        }
        if indexPath.section == 1 {
            detailsViewController.selectedTask = doneTaskList[indexPath.row]
            detailsViewController.isDoneTask = true
        }
        detailsViewController.buttonSaveUpdate = Constants.ButtonTitles.update
        detailsViewController.moc = moc
        self.navigationController?.pushViewController(detailsViewController, animated: true)
    }
    
    func registerTableViewCell() {
        let nib = UINib(nibName: "TaskTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "taskCell")
    }
}

