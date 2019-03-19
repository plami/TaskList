//
//  TaskService.swift
//  TaskManager
//
//  Created by macbook on 15.03.19.
//  Copyright © 2019 macbook. All rights reserved.
//

import Foundation
import CoreData

enum CategoryType: String, CaseIterable {
    case work = "work"
    case household = "household"
    case hobby = "hobby"
    case sport = "sport"
    case shopping = "shopping"
    case cooking = "cooking"
    
    var categoryColor: String {
        switch self {
        case .work:
            return "#C6DA02"
        case .household:
            return "#79A700"
        case .hobby:
            return "#F68B2C"
        case .sport:
            return "#E2B400"
        case .shopping:
            return "#F5522D"
        case .cooking:
            return "#FF6E83"
        }
    }
}

typealias TaskHandler = (Bool, [Task]) -> ()

class TaskService {
    private let moc: NSManagedObjectContext
    private var tasks = [Task]()
    private var pendingTasks = [Task]()
    private var doneTasks = [Task]()
    private var categories = [Category]()
    
    init(moc: NSManagedObjectContext) {
        self.moc = moc
    }
    
    //MARK - Public
    
    //READ
    func getPendingTasks() -> [Task]? {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        
        do {
            tasks = try moc.fetch(request)
            for task in tasks {
                if !task.finished {
                    pendingTasks.append(task)
                }
            }
            return pendingTasks
        } catch let error {
            print("Error fetching students: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    func getDoneTasks() -> [Task]? {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        
        do {
            tasks = try moc.fetch(request)
            for task in tasks {
                if task.finished {
                    doneTasks.append(task)
                }
            }
            return doneTasks
        } catch let error {
            print("Error fetching students: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    func getAvailableCategories() -> [Category]? {
        
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        
        do {
            categories = try moc.fetch(request)
            return categories
        } catch let error {
            print("Error fetching lessons: \(error.localizedDescription)")
        }
        
        return nil
        
    }
    
    //CREATE
    func addTask(title: String, completionDate: String, categoryColor: String, finished: Bool, for category: CategoryType,  completion: TaskHandler){
        let task = Task(context: moc)
        task.title = title
        task.completionDate = completionDate
        task.categoryColour = categoryColor
        task.finished = finished
        
        if let category = categoryExists(category) {
            addTaskForCategory(task, for: category)
            tasks.append(task)
            
            completion(true, tasks)
        }
        
        save()
    }
    
    // DELETE
    func deleteDoneTask(task: Task) {
        let category = task.category
        
        doneTasks = doneTasks.filter( { $0 != task })
        category?.removeFromTasks(task)
        moc.delete(task)
        save()
    }
    
    func deletePendingTask(task: Task) {
        let category = task.category
        
        doneTasks = doneTasks.filter( { $0 != task })
        category?.removeFromTasks(task)
        moc.delete(task)
        save()
    }
    
    //UPDATE
    func moveFromPendingToDoneTask(currentTask task: Task, withStatus finished: Bool, forCategory category: String) {
        let category = task.category
        let taskList = Array(category?.tasks?.mutableCopy() as! NSMutableSet) as! [Task]
        
        if let index = taskList.index(where: { $0 == task }) {
            taskList[index].finished = finished
            category?.tasks = NSSet(array: taskList)
        }
        save()
    }
    
    func updateTask(currentTask task: Task,title: String, completionDate: String, categoryColor: String, forCategory category: String) {
        if let categoryType = CategoryType(rawValue: category),
            let category = categoryExists(categoryType) {
            category.removeFromTasks(task)
            
            task.title = title
            task.completionDate = completionDate
            task.categoryColour = categoryColor
            addTaskForCategory(task, for: category)
        }
        save()
    }
    
    //MARK - Private
    private func categoryExists(_ type: CategoryType) -> Category? {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "name = %@", type.rawValue)
        
        var category: Category?
        do {
            let result = try moc.fetch(request)
            category = result.isEmpty ? addNewCategory(category: type) : result.first
        } catch let error {
            print("Error getting error: \(error.localizedDescription)")
        }
        
        return category
    }
    
    private func addNewCategory(category type: CategoryType) -> Category {
        let category = Category(context: moc)
        category.name = type.rawValue
        category.color = type.categoryColor
        
        return category
    }

    private func addTaskForCategory(_ task: Task, for category: Category) {
        task.category = category
    }
    
    private func save(completion: ((Bool) -> Void)? = nil) {
        let success: Bool
        do {
            try moc.save()
            success = true
        } catch let error {
            print("Saved error: \(error.localizedDescription)")
            moc.rollback()
            success = false
        }
        
        if let completion = completion {
            completion(success)
        }
    }
}
