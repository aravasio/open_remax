import Foundation
import GRDB

let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
var newListings = [Listing]()

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
    let fetchModule = FetchModule()
    let listings: [Listing]
    do {
        listings = try await fetchModule.fetch()
        print("Total listings fetched: \(listings.count)")
    } catch {
        print("Error fetching listings: \(error)")
        return
    }
    
    try listings.forEach {
        try dbModule.insert(listing: $0)
    }
    
    // Print the number of rows in the database
    do {
        try await dbQueue.read { db in
            let count = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM listing") ?? 0
            print("Rows in database: \(count)")
        }
    } catch {
        print("Error reading database: \(error)")
    }
    
    // Print information based on newListings array
    if newListings.isEmpty {
        print("No new listings were added to the database.")
    } else {
        print("New listings added to the database:")
        for listing in newListings {
            print(listing)
        }
    }
    
    print("end ...")
    semaphore.signal()
}

semaphore.wait()
