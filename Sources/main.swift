import Foundation
import GRDB
import Combine

// Function to fetch listings
func fetchListings(fetchModule: FetchModule) async throws -> [ListingDetail] {
    return try await fetchModule.fetch()
}

// Function to insert listings into the database
func insert(listings: [ListingDetail], into db: DBModule) async throws -> [ListingDetail] {
    var newListings: [ListingDetail] = []
    for listing in listings {
        if try !db.listingExists(listing: listing) {
            newListings.append(listing)
            try db.insert(listing: listing)
        }
    }
    return newListings
}

// Function to handle the final processing based on newListings array
func processNewListings(newListings: [ListingDetail]) {
    if newListings.isEmpty {
        print("No new listings were added to the database.")
    } else {
        print("New listings added to the database:")
        for listing in newListings {
            print(listing)
        }
    }
}

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
        let listings = try await fetchListings(fetchModule: fetchModule)
        let newListings = try await insert(listings: listings, into: dbModule)
        processNewListings(newListings: newListings)
        print("End of main function.")
    } catch {
        print("An error occurred: \(error)")
    }
}

// Call the main function to start execution
await main()

//fetchAndTrimHTML(url: "https://www.remax.com.ar/listings/departamento-venta-3-ambientes-belgrano-r")
