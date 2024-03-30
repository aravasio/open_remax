import Foundation
import GRDB

let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)

//Task {
//    let dbModule = SQLiteModule()
//    do {
//        try dbModule.initializeDB()
//        try dbModule.clearListingTable()
//        print("Listing table cleared successfully")
//    } catch {
//        print("Error clearing listing table: \(error)")
//    }
//}

Task {
    print("running ...")

    // Initialize the database queue using DBModule
    let dbModule: DBModule = SQLiteModule()
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
            try dbModule.insert(listing: listing)
        }
    }
    
    try await dbQueue.read { db in
        let count = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM listing") ?? 0
        print("Rows in db: \(count)")
    }
    
    print("end ...")
    semaphore.signal()
}

semaphore.wait()
