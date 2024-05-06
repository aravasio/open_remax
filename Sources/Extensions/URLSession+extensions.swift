import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking

extension URLSession {
    func data(from url: URL) async throws -> (Data, URLResponse) {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(Data, URLResponse), Error>) in
            let task: URLSessionDataTask = dataTask(with: url) { (data: Data?, response: URLResponse?, error: Error?) in
                if let error: Error = error {
                    continuation.resume(throwing: error)
                } else if let data: Data = data, let response: URLResponse = response {
                    continuation.resume(returning: (data, response))
                } else {
                    // Handle unexpected error
                    let error: NSError = NSError(
                        domain: "",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid response or data"]
                    )
                    continuation.resume(throwing: error)
                }
            }
            task.resume()
        }
    }
}
#endif
