import Foundation
import NIO
import AsyncHTTPClient
import SwiftSoup
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

protocol ServiceProvider {
    func fetchPropertyListings(neighborhoods: String, pageSize: Int) async -> Result<String, Error>
    func extractListings(from htmlString: String) -> [Listing]
}

class RemaxProvider: ServiceProvider {
    
    private let neighborhoods: String = "25006@Belgrano," +
    "25012@Coghlan," +
    "25013@Colegiales," +
    "25028@Parque%20Chas," +
    "25054@Villa%20Urquiza"
    
    private let pageSize: Int = 500
    private let retryTolerance: Int = 0
    
    func fetch(retryCount: Int = 0) async throws -> [Listing] {
        Debug.shared.log("fetching ...")
        let result: Result<String, Error> = await fetchPropertyListings(neighborhoods: neighborhoods, pageSize: pageSize)
        
        switch result {
        case let .success(htmlString):
            Debug.shared.log("success!")
            let listings: [Listing] = extractListings(from: htmlString)
            return listings
            
        case let .failure(error):
            Debug.shared.log("Error: \(error)")
            if retryCount < retryTolerance {
                Debug.shared.log("Retrying ... \(retryCount+1)/\(retryTolerance)")
                return try await fetch(retryCount: retryCount + 1)
            } else {
                throw error
            }
        }
    }
    
    func fetchPropertyListings(neighborhoods: String, pageSize: Int) async -> Result<String, Error> {
        #if os(macOS)
        await macOSFetchListings(neighborhoods: neighborhoods, pageSize: pageSize)
        #elseif os(Linux)
        await linuxFetchListings(neighborhoods: neighborhoods, pageSize: pageSize)
        #endif
        
    }
    
    #if os(macOS)
    func macOSFetchListings(neighborhoods: String, pageSize: Int) async -> Result<String, Error> {
        guard let url: URL = URL(
            string: "https://www.remax.com.ar/listings/buy?" +
            "page=0&" +
            "pageSize=\(pageSize)&" +
            "sort=-priceUsd&" +
            "in:operationId=1&" +
            "in:typeId=1,2,3,4,5,6,7,8,9,10,11,12&" +
            "pricein=1:200000:250000&" +
            "locations=in::::\(neighborhoods):::"
        ) else {
            return .failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil))
        }
        
        do {
            let htmlString: String = try String(contentsOf: url, encoding: .utf8)
            return .success(htmlString)
        } catch {
            return .failure(error)
        }
    }
    #endif
    
    #if os(linux)
    func linuxFetchListings(neighborhoods: String, pageSize: Int) async -> Result<String, Error> {
        
        let urlString: String = "https://www.remax.com.ar/listings/buy?" +
        "page=0&" +
        "pageSize=\(pageSize)&" +
        "sort=-priceUsd&" +
        "in:operationId=1&" +
        "in:typeId=1,2,3,4,5,6,7,8,9,10,11,12&" +
        "pricein=1:200000:250000&" +
        "locations=in::::\(neighborhoods):::"
        
        guard let _: URL = URL(string: urlString) else {
            return .failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil))
        }
        
        Debug.shared.log("fetching from: \(urlString)")
        
        do {
            let httpClient: HTTPClient = HTTPClient(eventLoopGroupProvider: .singleton)
            defer { Task { try await httpClient.shutdown() } }
            
            /// MARK: - Using Swift Concurrency
            var request: HTTPClientRequest = HTTPClientRequest(url: urlString)
            request.method = .GET
            
            // Set headers as seen in the browser request
            request.headers.add(name: "Accept",
                                value: "text/html")
            request.headers.add(name: "Accept-Encoding",
                                value: "identity") //value: "identity")
            request.headers.add(name: "Accept-Language",
                                value: "en-US,en;q=0.5")
            request.headers.add(name: "User-Agent",
                                value: "Mozilla/5.0 (X11; Linux x86_64; rv:123.0) Gecko/20100101 Firefox/123.0")
            request.headers.add(name: "Connection",
                                value: "keep-alive")
            
            let response: HTTPClientResponse = try await httpClient.execute(request, timeout: .seconds(30))
            
            switch response.status {
            case .ok:
                let buffer: NIO.ByteBuffer = try await response.body.collect(upTo: 1024 * 1024 * 500) // 50 MB
                guard let body: String = buffer.getString(at: 0, length: buffer.readableBytes) else {
                    return .failure(NSError(domain: "Data Encoding Error", code: 1, userInfo: nil))
                }
                
                return .success(body)
                
            default:
                print(response.status)
                return .failure(NSError(domain: "Unexpected response.status", code: 2, userInfo: nil))
            }
            
        } catch {
            return .failure(error)
        }
    }
    #endif
    
    
    func extractListings(from htmlString: String) -> [Listing] {
        var extractedListings: [Listing] = []
        
        do {
            let document: Document = try SwiftSoup.parse(htmlString)
            let listingsElements: Elements = try document.select("div.card-remax")
            try listingsElements.forEach { (element: SwiftSoup.Element) in
                try extractedListings.append(createListingItem(from: element))
            }
        } catch {
            fatalError("Error: \(error)")
        }
        
        return extractedListings
    }
    
    fileprivate func createListingItem(from element: SwiftSoup.Element) throws -> Listing {
        do {
            let address: String = try element.select("p.card__address").text()
            let price: String = try element.select("p.card__price").text()
            let description: String = try element.select("p.card__description").text()
            let totalArea: String = try element.select("div.card__feature--item.feature--m2total span").text()
            let coveredArea: String = try element.select("div.card__feature--item.feature--m2cover span").text()
            let rooms: String = try element.select("div.card__feature--item.feature--ambientes span").text()
            let bathrooms: String = try element.select("div.card__feature--item.feature--bathroom span").text()
            
            return Listing(
                address: address,
                price: price,
                description: description,
                totalArea: totalArea,
                coveredArea: coveredArea,
                rooms: rooms,
                bathrooms: bathrooms
            )
        } catch {
            throw error
        }
    }
}
