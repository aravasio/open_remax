import Foundation
import GRDB

let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)

Task {
    print("running ...")

    // Initialize the database queue using DBModule
    let dbModule = DBModule()
    guard let dbQueue = try? dbModule.initializeDB() else {
        print("Failed to initialize database")
        return
    }
    
    // Check if the database file exists
    if dbModule.databaseFileExists() {
        print("Database file exists")
    } else {
        print("Database file does not exist")
    }
    
    // Check if the database contains data
    do {
        if try dbModule.databaseContainsData() {
            print("Database contains data")
        } else {
            print("Database does not contain data")
        }
    } catch {
        print("Error checking database data: \(error)")
    }
    
    // Fetch listings using FetchModule
    let listings: [Listing] = try await FetchModule().fetch()
    print("total: \(listings.count)")

    // Perform database operations
    try await dbQueue.write { db in
        for var listing in listings {
            // Insert listing into the database
            try listing.insert(db)
        }
    }
    
    print("end ...")
    semaphore.signal()
}

semaphore.wait()
