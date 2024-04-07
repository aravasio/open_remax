import Foundation
//import NIO
//import AsyncHTTPClient
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

fileprivate protocol ServiceProvider {
    func fetch(retryCount: Int) async throws -> [ListingDetail]
}

enum ApartmentListingError: Error {
    case parsingFailed(reason: String)
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
        
        private let pageSize: Int = 500
        private let retryTolerance: Int = 0
        
        func fetch(retryCount: Int = 0) async throws -> [ListingDetail] {
            guard let url: URL = URL(
                string: "https://api-ar.redremax.com/remaxweb-ar/api/listings/findAll?" +
                "page=0&" +
                "pageSize=\(pageSize)&" +
                "sort=-priceUsd&" +
                "in:operationId=1&" +
                "in:typeId=1,2,3,4,5,6,7,8,9,10,11,12&" +
                "pricein=1:200000:250000&" +
                "locations=in::::\(neighborhoods):::"
            ) else {
                throw NSError(domain: "Invalid URL", code: 0, userInfo: nil)
            }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let slugs = try JSONDecoder().decode(ApiQueryResponse.self, from: data).page.slugs
                
                return try await fetchData(from: slugs)
            } catch {
                throw error
            }
        }
        
        private func fetchData(from slugs: [ListingSlug]) async throws -> [ListingDetail] {
            var listingDetails: [ListingDetail] = []
            for slug in slugs {
                guard let url: URL = URL(
                    string: "https://api-ar.redremax.com/remaxweb-ar/api/listings/findBySlug/\(slug.value)"
                ) else {
                    throw NSError(domain: "Invalid URL", code: 0, userInfo: nil)
                }
                let (data, _) = try await URLSession.shared.data(from: url)
                let response = try JSONDecoder().decode(ListingDetailsResponse.self, from: data)
                listingDetails.append(response.data)
            }
            
            return listingDetails
        }
    }
}
