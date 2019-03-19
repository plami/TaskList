//
//  Task+CoreDataProperties.swift
//  TaskManager
//
//  Created by macbook on 16.03.19.
//  Copyright © 2019 macbook. All rights reserved.
//
//

import Foundation
import CoreData


extension Task {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Task> {
        return NSFetchRequest<Task>(entityName: "Task")
    }

    @NSManaged public var categoryColour: String?
    @NSManaged public var completionDate: String?
    @NSManaged public var finished: Bool
    @NSManaged public var title: String?
    @NSManaged public var category: Category?

}
