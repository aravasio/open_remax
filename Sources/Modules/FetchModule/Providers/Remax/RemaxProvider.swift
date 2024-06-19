import Foundation
//import NIO
//import AsyncHTTPClient
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

fileprivate protocol ServiceProvider {
    func fetch() async throws -> [ListingDetail]
}

enum ApartmentListingError: Error {
    case parsingFailed(Error)
    case elementHasNoData
    case invalidURL
}

extension FetchModule {
    class RemaxProvider: ServiceProvider {
        
        private let neighborhoods: String = [
            "25006@Belgrano",
            "25012@Coghlan",
            "25013@Colegiales",
            "25028@Parque%20Chas",
            "25054@Villa%20Urquiza"
        ].joined(separator: ",")
        
        private let MIN_PRICE = 1
        private let MAX_PRICE = 999999999
        private let PAGE_SIZE: Int = 1000

        private var neighborhoodsFilter: String { "locations=in::::\(neighborhoods):::" }
        
        private let retryTolerance: Int = 0
        
        func fetch() async throws -> [ListingDetail] {
            do {
                let slugs = try await fetchSlugs()
                print("Fetched \(slugs.count) slugs...")
                let details = try await fetchDetails(from: slugs)
                return details
            } catch {
                throw error
            }
        }
        
        private func fetchSlugs(from page: Int = 0) async throws -> [ListingSlug] {
            guard let url: URL = URL(
                string: "https://api-ar.redremax.com/remaxweb-ar/api/listings/findAll?" +
                "page=\(page)&" +
                "pageSize=\(PAGE_SIZE)&" +
                "sort=-priceUsd&" +
                "in:operationId=1&" +
                "in:typeId=1,2,3,4,5,6,7,8,9,10,11,12&" +
                "pricein=1:\(MIN_PRICE):\(MAX_PRICE)&"
//                + neighborhoodsFilter
            ) else {
                throw NSError(domain: "Invalid URL", code: 0, userInfo: nil)
            }
            
            do {
                print(url)
                let (data, _) = try await URLSession.shared.data(from: url)
                let pageData = try JSONDecoder().decode(ApiQueryResponse.self, from: data).page
                var fetchedSlugs: [ListingSlug] = []
                print("Pages progress: \(pageData.page+1)/\(pageData.totalPages)")
                
                if page < pageData.totalPages {
                     fetchedSlugs = try await fetchSlugs(from: pageData.page + 1)
                }
                
                return pageData.slugs + fetchedSlugs
            } catch {
                throw error
            }
        }
        
        private func fetchDetails(from slugs: [ListingSlug]) async throws -> [ListingDetail] {
            let maxConcurrentTasks = 100  // Maximum number of concurrent tasks
            var details = [ListingDetail]()
            let progressTracker = ProgressTracker(total: slugs.count)
            
            return try await withThrowingTaskGroup(of: ListingDetail?.self, body: { group in
                for chunk in slugs.chunked(into: maxConcurrentTasks) {
                    for slug in chunk {
                        group.addTask {
                            do {
                                let result = try await self.fetchDetail(for: slug)
                                await progressTracker.increment()
                                return result
                            } catch {
                                print("Error fetching detail for slug: \(slug.value) - \(error)")
                                return nil  // Return nil for failed tasks
                            }
                        }
                    }
                    for try await detail in group {
                        if let detail = detail {
                            details.append(detail)
                        }
                    }
                }
                return details
            })
        }

        
        private func fetchDetail(for slug: ListingSlug) async throws -> ListingDetail {
//            print("Fetching detail for slug: \(slug.value)")
            guard let url = URL(string: "https://api-ar.redremax.com/remaxweb-ar/api/listings/findBySlug/\(slug.value)") else {
                throw ApartmentListingError.invalidURL
            }
            let (data, _) = try await URLSession.shared.data(from: url)
            
            do {
                let element = try JSONDecoder().decode(ListingDetailsResponse.self, from: data)
                guard let data = element.data else {
                    print(slug.value)
                    throw ApartmentListingError.elementHasNoData
                }
                
                return data
            } catch {
                throw ApartmentListingError.parsingFailed(error)
            }
        }
    }
}

fileprivate extension Array {
    /// Splits the array into chunks of the specified size.
    /// - Parameter size: The maximum number of elements per chunk.
    /// - Returns: An array of arrays where each sub-array has at most `size` elements.
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: self.count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, self.count)])
        }
    }
}

fileprivate actor ProgressTracker {
    private var count: Int = 0
    private let total: Int
    
    init(total: Int) {
        self.total = total
    }
    
    func increment() {
        count += 1
        print("Fetched \(count) out of \(total) details.")
    }
}
