import Foundation
import SwiftSoup

let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)

Task {    

    let provider: RemaxProvider = RemaxProvider()
    let result: [Listing] = try await provider.fetch(retryCount: 0)
    
    print(result.count)
    semaphore.signal()
}

semaphore.wait()
