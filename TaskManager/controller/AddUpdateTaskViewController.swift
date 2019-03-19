//
//  AddUpdateTaskViewController.swift
//  TaskManager
//
//  Created by macbook on 15.03.19.
//  Copyright © 2019 macbook. All rights reserved.
//

import UIKit
import CoreData

class AddUpdateTaskViewController: UIViewController {

    @IBOutlet weak var buttonSaveUpdateAction: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var dateTextfield: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var categoryNameTextField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!

    //MARK - Public Properties
    
    var moc: NSManagedObjectContext? {
        didSet {
            if let moc = moc {
                taskService = TaskService(moc: moc)
            }
        }
    }
    var selectedTask: Task?
    var buttonSaveUpdate: String?
    var isDoneTask: Bool?
    
    //MARK - Private Properties
    
    private var taskService: TaskService?
    private var categoryList = [Category]()
    private var taskList = [Task]()
    private var categoriesColors = [UIColor]()
    private var isFinished: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.leftBarButtonItem =
            UIBarButtonItem (title: "Back",
                             style: .plain,
                             target: self,
                             action: #selector(goBack))
        
        if selectedTask != nil {
            self.navigationItem.rightBarButtonItem =
                UIBarButtonItem (title: "Delete",
                                 style: .plain,
                                 target: self,
                                 action: #selector(deleteTask))
        }
        
        self.registerCustomCell()
        
        datePicker.addTarget(self, action: #selector(AddUpdateTaskViewController.handler), for: UIControl.Event.valueChanged)
        self.datePicker.isHidden = true
        buttonSaveUpdateAction.setTitle(buttonSaveUpdate, for: .normal)
        buttonSaveUpdateAction.addTarget(self, action: #selector(AddUpdateTaskViewController.saveTask), for: .touchUpInside)
        
        dateTextfield.inputView = UIView()
        categoryNameTextField.inputView = UIView()
        
        if selectedTask != nil {
            nameTextField.text = selectedTask?.title
            dateTextfield.text = selectedTask?.completionDate
            isFinished = selectedTask?.finished
            categoryNameTextField.text = selectedTask?.category?.name
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let availableCategories = taskService?.getAvailableCategories() {
            categoryList = availableCategories
        }
        
        for value in CategoryType.allCases {
            self.categoriesColors.append(UIColor(hexString: value.categoryColor))
        }
    }
    
    @objc func goBack() {
        self.performSegue(withIdentifier: "backToMain", sender: self)
    }
    
    @objc func deleteTask() {
        guard let isDoneTask = isDoneTask,
            let selectedTask = selectedTask
            else { return }
        
        if !isDoneTask {
            self.taskService?.deletePendingTask(task: selectedTask)
        } else {
            self.taskService?.deleteDoneTask(task: selectedTask)
        }
        self.performSegue(withIdentifier: "backToMain", sender: self)
    }
    
    //MARK: Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "backToMain" {
            prepareSegueForAddTaskViewController(segue: segue)
        }
    }
    
    private func prepareSegueForAddTaskViewController(segue: UIStoryboardSegue) {
        guard let nav = segue.destination as? UINavigationController else {
            fatalError("NavigationController not found")
        }
        
        guard let taskListVC = nav.viewControllers.first as? TasksViewController else {
            fatalError("AddUpdateTaskViewController not found")
        }
        taskListVC.moc = moc
    }
    
    @objc func handler(sender: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"
        let selectedDate = dateFormatter.string(from: datePicker.date)
        self.dateTextfield.text = selectedDate
        self.datePicker.isHidden = true
    }
    
    @objc func saveTask() {
        guard let taskName = nameTextField.text,
            let category = categoryNameTextField.text,
            let date = dateTextfield.text
        else { return }
        
        if let categoryType = CategoryType(rawValue: category.lowercased()) {
            if (selectedTask == nil) {
                self.taskService?.addTask(title: taskName, completionDate: date, categoryColor: categoryType.categoryColor, finished: false, for: categoryType, completion: { (success, tasks) in
                    if success {
                        self.taskList = tasks
                        self.performSegue(withIdentifier: "backToMain", sender: self)
                    }
                })
            } else {
                self.taskService?.updateTask(currentTask: selectedTask!, title: taskName, completionDate: date, categoryColor: categoryType.categoryColor, forCategory: category)
                self.performSegue(withIdentifier: "backToMain", sender: self)
            }
        }
    }
}

//MARK: CollectionViewDelegates
extension AddUpdateTaskViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categoriesColors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "colorCell", for: indexPath) as! ColorCollectionViewCell
        
        cell.backgroundColor = categoriesColors[indexPath.row]
        
        return cell
    }
    
    func registerCustomCell() {
        
        let nib = UINib(nibName: "ColorCollectionViewCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "colorCell")
    }
}

//MARK: TextFieldDelegates
extension AddUpdateTaskViewController: UITextFieldDelegate, UIActionSheetDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == dateTextfield {
            self.datePicker.isHidden = false
        }
        if textField == categoryNameTextField {
            
            let actionSheet = UIAlertController.init(title: "Please select a category", message: nil, preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction.init(title: CategoryType.cooking.rawValue, style: UIAlertAction.Style.default, handler: { [weak self] (action) in
                self?.categoryNameTextField.text = CategoryType.cooking.rawValue
            }))
            actionSheet.addAction(UIAlertAction.init(title: CategoryType.hobby.rawValue, style: UIAlertAction.Style.default, handler: { [weak self] (action) in
                self?.categoryNameTextField.text = CategoryType.hobby.rawValue
            }))
            actionSheet.addAction(UIAlertAction.init(title: CategoryType.household.rawValue, style: UIAlertAction.Style.default, handler: { [weak self] (action) in
                self?.categoryNameTextField.text = CategoryType.household.rawValue
            }))
            actionSheet.addAction(UIAlertAction.init(title: CategoryType.shopping.rawValue, style: UIAlertAction.Style.default, handler: { [weak self] (action) in
                self?.categoryNameTextField.text = CategoryType.shopping.rawValue
            }))
            actionSheet.addAction(UIAlertAction.init(title: CategoryType.sport.rawValue, style: UIAlertAction.Style.default, handler: { [weak self] (action) in
                self?.categoryNameTextField.text = CategoryType.sport.rawValue
            }))
            actionSheet.addAction(UIAlertAction.init(title: CategoryType.work.rawValue, style: UIAlertAction.Style.default, handler: { [weak self] (action) in
                self?.categoryNameTextField.text = CategoryType.work.rawValue
            }))
            actionSheet.addAction(UIAlertAction.init(title: "Cancel", style: UIAlertAction.Style.cancel, handler: { (action) in
            }))
            //Present the controller
            self.present(actionSheet, animated: true, completion: nil)
        }
    }
}
