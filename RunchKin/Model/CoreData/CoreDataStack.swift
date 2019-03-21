//
//  CoreDataStack.swift
//  RunchKin
//
//  Created by Madison Waters on 3/19/19.
//  Copyright © 2019 Jonah Bergevin. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack {
    
    static let persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "RunchKin")
        container.loadPersistentStores { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error with Core Data Stack\(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    static var context: NSManagedObjectContext { return persistentContainer.viewContext }
    
    class func saveContext() {
        let context = persistentContainer.viewContext
        
        guard context.hasChanges else {
            return
        }
        
        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            fatalError("Error saving Core Data Stack context\(error), \(nserror.userInfo)")
        }
    }
}
