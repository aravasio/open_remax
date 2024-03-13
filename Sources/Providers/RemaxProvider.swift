import Foundation
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
    private let retryTolerance: Int = 5

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

    func extractListings(from htmlString: String) -> [Listing] {
        var extractedListings: [Listing] = []
        
        do {
            let document: Document = try SwiftSoup.parse(htmlString)
            let listingsElements: Elements = try document.select("div.card-remax") 
            try listingsElements.forEach { (element: SwiftSoup.Element) in
                try extractedListings.append(createListingItem(from: element))
            }
        } catch {
            print("Error: \(error)")
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
