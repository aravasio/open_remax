import Foundation
import SwiftSoup

let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)

Task {    
    Debug.shared.log("Start ...")

    let provider: RemaxProvider = RemaxProvider()
    let result: [Listing] = try await provider.fetch(retryCount: 0)
    print(result.count)

    Debug.shared.log("End ...")
    semaphore.signal()
}

semaphore.wait()