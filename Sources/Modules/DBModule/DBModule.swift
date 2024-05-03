import Foundation
import GRDB

protocol DBModule {
    var dbQueue: DatabaseQueue? { get set }
    
    func initializeDB() throws -> DatabaseQueue
    func databaseFileExists() -> Bool
//    func getAllData(from tableName: String) throws -> [Row]
    func databaseContainsData() throws -> Bool
    func listingExists(listing: ListingDetail) throws -> Bool
    func insert(listings: [ListingDetail]) throws
    func clearListingTable() throws
}


class SQLiteModule: DBModule {
    let dbDirectoryPath: String = "./local_database"
    var dbFilePath: String { "\(dbDirectoryPath)/homer.sqlite" }
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
        print(FileManager.default.currentDirectoryPath)
        
        return queue
    }
    
    // Check if the database file exists
    func databaseFileExists() -> Bool {
        return FileManager.default.fileExists(atPath: dbFilePath)
    }
    
//    func getAllData(from tableName: String) throws -> [Row] {
//        guard let queue = dbQueue else {
//            let message = "Database queue is not initialized"
//            throw NSError(domain: "DBModule", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
//        }
//        
//        return try queue.read { db in
//            let rows = try Row.fetchAll(db, sql: "SELECT * FROM \(tableName)")
//            return rows
//        }
//    }
    
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
    
    // Check if a listing already exists in the table
    func listingExists(listing: ListingDetail) throws -> Bool {
        guard let queue = dbQueue else {
            throw NSError(
                domain: "DBModule",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Database queue is not initialized"]
            )
        }
    
        let query = """
        SELECT COUNT(*)
        FROM listing 
        WHERE slug = ?
        AND description = ?
        """
        
        // Collect parameters from the listing
        let parameters = [
            listing.slug,
            listing.description,
        ] as [Any]
        
        // Execute the query with parameters
        return try queue.read { db in
            var count = 0
            // The fetchOne method automatically replaces placeholders with parameters from the array
            if let arguments = StatementArguments(parameters) {
                count = try Int.fetchOne(db, sql: query, arguments: arguments) ?? 0
            }
            return count > 0
        }
    }
    
    // Add a new listing to the table if it doesn't already exist
    func insert(listings: [ListingDetail]) throws {
        guard let queue = dbQueue else {
            let message = "Database queue is not initialized"
            throw NSError(domain: "DBModule", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
        }
        
        try queue.inTransaction { db in
            for listing in listings {
                var mutableListing = listing
                try mutableListing.insert(db, onConflict: .ignore)
            }
            return .commit
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
    
    // Create the "listing" table if it doesn't exist
    private func createListingTable() throws {
        guard let queue = dbQueue else {
            let message = "Database queue is not initialized"
            throw NSError(domain: "DBModule", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
        }
        try queue.write { db in
            if try !db.tableExists("listing") {
                try db.create(table: "listing") { table in
                    
                    table.column("id", .text)//.primaryKey().notNull()
                    table.column("internal_id", .text).primaryKey().notNull()
                    table.column("title", .text).notNull()
                    table.column("slug", .text).notNull()
                    table.column("description", .text).notNull()
                    table.column("location_altitude", .double).notNull()
                    table.column("location_latitude", .double).notNull()
                    table.column("total_rooms", .numeric)
                    table.column("bedrooms", .numeric)
                    table.column("bathrooms", .numeric)
                    table.column("toilets", .numeric)
                    table.column("floors", .numeric)
                    table.column("pozo", .boolean)
                    table.column("parking_spaces", .numeric)
                    table.column("year_built", .numeric)
                    table.column("price", .double)
                    table.column("price_exposure", .boolean)
                    table.column("currency", .text)
                    table.column("expenses_price", .double)
                    table.column("expenses_currency", .text)
                    table.column("apt_professional_use", .boolean)
                    table.column("apt_commercial_use", .boolean)
                    table.column("apt_credit", .boolean)
                    table.column("offers_financing", .boolean)
                    table.column("in_private_community", .boolean)
                    table.column("video", .text)
                    table.column("reduced_mobility_compliant", .boolean)
                    table.column("display_address", .text)
                    table.column("total_lot_size", .double)
                    table.column("total_area_built", .double)
                    table.column("total_squared_meters_covered", .double)
                    table.column("total_squared_meters_semicovered", .double)
                    table.column("total_squared_meters_uncovered", .double)
                    table.column("quotes", .double)
                    table.column("fee_quote", .double)
                    table.column("conditions", .text)
                    table.column("type", .text)
                    table.column("operation", .text)
                    table.column("listing_status", .text)
                    table.column("features", .text)
                    table.column("photos", .text)
                    table.column("opportunity", .text)
                }
            }
        }
    }
}
