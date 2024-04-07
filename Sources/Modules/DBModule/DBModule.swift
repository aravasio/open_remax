import Foundation
import GRDB

protocol DBModule {
    var dbQueue: DatabaseQueue? { get set }
    
    func initializeDB() throws -> DatabaseQueue
    func databaseFileExists() -> Bool
//    func getAllData(from tableName: String) throws -> [Row]
    func databaseContainsData() throws -> Bool
    func listingExists(listing: ListingDetail) throws -> Bool
    func insert(listing: ListingDetail) throws
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
        
        // Define the SQL query with each condition on its own line
        
        /*
         container["id"] = id
         //        container["title"] = title
         container["slug"] = slug
         container["description"] = description
         container["location_latitude"] = location.coordinates[0]
         container["location_altitude"] = location.coordinates[1]
         container["total_rooms"] = totalRooms
         container["bedrooms"] = bedrooms
         container["bathrooms"] = bathrooms
         container["toilets"] = toilets
         container["floors"] = floors
         container["pozo"] = pozo
         container["parking_spaces"] = parkingSpaces
         container["video"] = video
         container["year_built"] = yearBuilt
         container["price"] = price
         container["price_exposure"] = priceExposure
         container["currency"] = currency.value
         container["expenses_price"] = expensesPrice
         container["expenses_currency"] = expensesCurrency.value
         container["apt_professional_use"] = professionalUse
         container["apt_commercial_use"] = commercialUse
         container["remax_collection"] = remaxCollection
         container["offers_financing"] = financing
         container["apt_credit"] = aptCredit
         container["in_private_community"] = inPrivateCommunity
         container["internal_id"] = internalId
         container["display_address"] = displayAddress
         container["total_squared_meters"] = dimensionLand
         container["total_area_built"] = dimensionTotalBuilt
         container["total_squared_meters_covered"] = dimensionCovered
         container["total_squared_meters_semicovered"] = dimensionSemicovered
         container["total_squared_meters_uncovered"] = dimensionUncovered
         container["quotes"] = quotes
         container["fee_quotes"] = feeQuotes
         */
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
    func insert(listing: ListingDetail) throws {
        guard let queue = dbQueue else {
            let message = "Database queue is not initialized"
            throw NSError(domain: "DBModule", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
        }
        
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
    
    // Create the "listing" table if it doesn't exist
    private func createListingTable() throws {
        guard let queue = dbQueue else {
            let message = "Database queue is not initialized"
            throw NSError(domain: "DBModule", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
        }
        try queue.write { db in
            if try !db.tableExists("listing") {
                try db.create(table: "listing") { table in
                    table.column("id", .text).primaryKey().notNull()
                    table.column("title", .text).notNull()
                    table.column("slug", .text).notNull()
                    table.column("description", .text).notNull()
                    table.column("location_altitude", .double).notNull()
                    table.column("location_latitude", .double).notNull()
                    
                    table.column("total_rooms", .integer).notNull()
                    table.column("bedrooms", .integer).notNull()
                    table.column("bathrooms", .integer).notNull()
                    table.column("toilets", .integer).notNull()
                    table.column("floors", .integer).notNull()
                    table.column("pozo", .boolean).notNull()
                    table.column("parking_spaces", .integer).notNull()
//                    table.column("video", .text)
                    table.column("year_built", .integer)
                    table.column("price", .double)
                    table.column("price_exposure", .boolean)
                    table.column("currency", .text)
                    table.column("expenses_price", .double)
                    table.column("expenses_currency", .text)
                    table.column("apt_professional_use", .boolean).notNull()
                    table.column("apt_commercial_use", .boolean).notNull()
                    table.column("remax_collection", .boolean).notNull()
                    table.column("offers_financing", .boolean).notNull()
                    table.column("apt_credit", .boolean).notNull()
                    table.column("in_private_community", .boolean).notNull()
                    table.column("internal_id", .text).notNull()
                    table.column("display_address", .text).notNull()
                    table.column("total_squared_meters", .double).notNull()
                    table.column("total_area_built", .double).notNull()
                    table.column("total_squared_meters_covered", .double).notNull()
                    table.column("total_squared_meters_semicovered", .double).notNull()
                    table.column("total_squared_meters_uncovered", .double).notNull()

                    table.column("associate", .double)
                    table.column("property_type", .double)
                    table.column("operation", .double)
                    table.column("listing_status", .double)
                    table.column("opportunity", .double)
                    table.column("photos", .double)
                    table.column("conditions", .double)
                    table.column("features", .double)
                    table.column("virtual_tours", .double)
                    table.column("list_broker", .double)
                    
                    table.column("quotes", .integer)
                    table.column("fee_quotes", .double)
                }
            }
        }
    }
}
