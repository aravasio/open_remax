import Foundation
import GRDB

class DBModule {
    
    let dbDirectoryPath: String = "./Sources/Modules/DBModule"
    var dbFilePath: String { "\(dbDirectoryPath)/HomeR.sqlite" }
    var dbQueue: DatabaseQueue?

    // Create the database file if needed and return the database queue
    func initializeDB() throws -> DatabaseQueue {
        if dbQueue == nil {
            // Create the database file if needed
            createIfNeeded()
            
            // Initialize the database queue
            dbQueue = try DatabaseQueue(path: dbFilePath)
            
            // Create the "listing" table if it doesn't exist
            try createListingTable()
        }
        // Return the database queue
        guard let queue = dbQueue else {
            throw NSError(domain: "DBModule", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize database"])
        }
        return queue
    }
    
    // Check if the database file exists
    func databaseFileExists() -> Bool {
        return FileManager.default.fileExists(atPath: dbFilePath)
    }
    
    // Check if the "listing" table exists and if it contains data
    func getData(from tableName: String) throws -> [Row] {
        guard let queue = dbQueue else {
            throw NSError(domain: "DBModule", code: 1, userInfo: [NSLocalizedDescriptionKey: "Database queue is not initialized"])
        }
        
        return try queue.read { db in
            let rows = try Row.fetchAll(db, sql: "SELECT * FROM \(tableName)")
            return rows
        }
    }
    
    // Create the database file if it doesn't exist
    private func createIfNeeded() {
        guard !FileManager.default.fileExists(atPath: dbFilePath) else { return }
        do {
            try FileManager.default.createDirectory(atPath: dbDirectoryPath, withIntermediateDirectories: true, attributes: nil)
            FileManager.default.createFile(atPath: dbFilePath, contents: nil, attributes: nil)
        } catch {
            print("Error creating database file: \(error)")
        }
    }
    
    // Create the "listing" table if it doesn't exist
    private func createListingTable() throws {
        guard let queue = dbQueue else {
            throw NSError(domain: "DBModule", code: 1, userInfo: [NSLocalizedDescriptionKey: "Database queue is not initialized"])
        }
        try queue.write { db in
            if try !db.tableExists("listing") {
                try db.create(table: "listing") { table in
                    table.autoIncrementedPrimaryKey("id")
                    table.column("address", .text).notNull()
                    table.column("price", .text).notNull()
                    table.column("description", .text).notNull()
                    table.column("totalArea", .text).notNull()
                    table.column("coveredArea", .text).notNull()
                    table.column("rooms", .text).notNull()
                    table.column("bathrooms", .text).notNull()
                }
            }
        }
    }
}
