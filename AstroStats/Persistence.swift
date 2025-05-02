//
//  Persistence.swift
//  AstroStats
//
//  Created by Errick Williams on 5/1/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    // Optional preview setup (not required unless you want mock data for SwiftUI previews)
    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // Optional: Preload a ChartEntity for SwiftUI preview
        let previewEntity = ChartEntity(context: viewContext)
        previewEntity.id = UUID()
        previewEntity.name = "Preview Person"
        previewEntity.birthDate = Date()
        previewEntity.birthPlace = "Austin, TX"
        previewEntity.latitude = 30.2672
        previewEntity.longitude = -97.7431
        previewEntity.timeZoneID = "America/Chicago"

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("❌ Failed to save preview: \(nsError), \(nsError.userInfo)")
        }

        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "AstroStats") // must match your .xcdatamodeld file name exactly

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved Core Data error: \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
