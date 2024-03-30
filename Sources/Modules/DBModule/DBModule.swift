import Foundation
import GRDB

protocol DBModule {
    var dbQueue: DatabaseQueue? { get set }

    func initializeDB() throws -> DatabaseQueue
    func databaseFileExists() -> Bool
    func getAllData(from tableName: String) throws -> [Row]
    func databaseContainsData() throws -> Bool
    func insert(listing: Listing) throws
    func clearListingTable() throws
}


class SQLiteModule: DBModule {
    let dbDirectoryPath: String = "./Sources/Modules/DBModule"
    var dbFilePath: String { "\(dbDirectoryPath)/HomeR.sqlite" }
    var dbQueue: DatabaseQueue?
    
    // Create the database file if needed and return the database queue
    func initializeDB() throws -> DatabaseQueue {
        if dbQueue == nil {
            // Create the database file if needed
            createDBFileIfNeeded()
            
            // Initialize the database queue
            dbQueue = try DatabaseQueue(path: dbFilePath)
            
            // Create the "listing" table if it doesn't exist
            try createListingTable()
        }
        // Return the database queue
        guard let queue = dbQueue else {
            let message = "Failed to initialize database"
            throw NSError(domain: "DBModule", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
        }
        return queue
    }
    
    // Check if the database file exists
    func databaseFileExists() -> Bool {
        return FileManager.default.fileExists(atPath: dbFilePath)
    }
    
    // Check if the "listing" table exists and if it contains data
    func getAllData(from tableName: String) throws -> [Row] {
        guard let queue = dbQueue else {
            let message = "Database queue is not initialized"
            throw NSError(domain: "DBModule", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
        }
        
        return try queue.read { db in
            let rows = try Row.fetchAll(db, sql: "SELECT * FROM \(tableName)")
            return rows
        }
    }
    
    // Check if the "listing" table exists and if it contains data
    func databaseContainsData() throws -> Bool {
        guard let queue = dbQueue else {
            let message = "Database queue is not initialized"
            throw NSError(domain: "DBModule", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
        }
        
        return try queue.read { db in
            let count = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM listing") ?? 0
            return count > 0
        }
    }
    
    // Add a new listing to the table if it doesn't already exist
    func insert(listing: Listing) throws {
        guard let queue = dbQueue else {
            let message = "Database queue is not initialized"
            throw NSError(domain: "DBModule", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
        }
        
        // Check if the listing already exists
        if try listingExists(listing: listing) {
            print("\(listing) already in table, skipped")
            return
        }
        
        // If the listing doesn't exist, add it to the table
        var listing = listing // We need a mutating value
        try queue.write { db in
            try listing.insert(db)
        }
    }

    // Clear all rows from the "listing" table
    func clearListingTable() throws {
        guard let queue = dbQueue else {
            let message = "Database queue is not initialized"
            throw NSError(domain: "DBModule", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
        }
        try queue.write { db in
            try db.execute(sql: "DELETE FROM listing")
        }
    }
    
    // Create the database file if it doesn't exist
    private func createDBFileIfNeeded() {
        guard !FileManager.default.fileExists(atPath: dbFilePath) else { return }
        do {
            let manager = FileManager.default
            try manager.createDirectory(atPath: dbDirectoryPath, withIntermediateDirectories: true, attributes: nil)
            manager.createFile(atPath: dbFilePath, contents: nil, attributes: nil)
        } catch {
            print("Error creating database file: \(error)")
        }
    }
    
    // Check if a listing already exists in the table
    private func listingExists(listing: Listing) throws -> Bool {
        guard let queue = dbQueue else {
            throw NSError(
                domain: "DBModule",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Database queue is not initialized"]
            )
        }
        
        // Define the SQL query with each condition on its own line
        let query = """
        SELECT COUNT(*)
        FROM listing
        WHERE address = ?
        AND price = ?
        AND description = ?
        AND totalArea = ?
        AND coveredArea = ?
        AND rooms = ?
        AND bathrooms = ?
        """
        
        // Collect parameters from the listing
        let parameters = [listing.address, listing.price, listing.description,listing.totalArea,
                          listing.coveredArea, listing.rooms, listing.bathrooms]
        
        // Execute the query with parameters
        return try queue.read { db in
            // The fetchOne method automatically replaces placeholders with parameters from the array
            let count = try Int.fetchOne(db, sql: query, arguments: StatementArguments(parameters)) ?? 0
            return count > 0
        }
    }

    // Create the "listing" table if it doesn't exist
    private func createListingTable() throws {
        guard let queue = dbQueue else {
            let message = "Database queue is not initialized"
            throw NSError(domain: "DBModule", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
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
