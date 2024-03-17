import Foundation
import SwiftSoup

let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)

Task {    

    print("running ...")
    let result: [Listing] = try await FetchModule().fetch()
    print("results: \(result.count)")
    
    // store listings into a DB
    // for each element
    // if listing already exists, check if there's new data on the element
    // if the listing does not exist, add it to the DB and add it to the list of "newly published listings" array

    semaphore.signal()
}

semaphore.wait()
