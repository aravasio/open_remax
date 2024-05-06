import Foundation
import GRDB
//import Combine

// Main function to coordinate tasks
func main() async {
    do {
        print("Start of main function.")
        // Initialize the database
        let dbModule = SQLiteModule()
        _ = try dbModule.initializeDB()
        
        // Logging database status with a more sophisticated logging system could be considered here
        print(dbModule.databaseFileExists() ? "Database file exists" : "Database file does not exist")
        
        // Check if the database contains data
        let databaseContainsData = try dbModule.databaseContainsData()
        print(databaseContainsData ? "Database contains data" : "Database does not contain data")
        
        // Fetch and insert listings
        let fetchModule = FetchModule()
        let startTime = Date()
        let listings = try await fetchModule.fetch()
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        print("Fetching listings took \(duration) seconds")
        print("storing into DB \(listings.count) items ...")
        try dbModule.insert(listings: listings)
        print("End of main function.")
    } catch {
        print("An error occurred: \(error)")
    }
}

// Call the main function to start execution
await main()
