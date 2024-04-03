import Foundation
import NIO
import AsyncHTTPClient
import SwiftSoup
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

fileprivate protocol ServiceProvider {
    func fetchListings(neighborhoods: String, pageSize: Int) async -> Result<String, Error>
    func extractListings(from htmlString: String) -> [Listing]
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
        
        func fetch(retryCount: Int = 0) async throws -> [Listing] {
            let result: Result<String, Error> = await fetchListings(neighborhoods: neighborhoods, pageSize: pageSize)
            
            switch result {
            case let .success(htmlString):
                let listings: [Listing] = extractListings(from: htmlString)
                return listings
                
            case let .failure(error):
                if retryCount < retryTolerance {
                    return try await fetch(retryCount: retryCount + 1)
                } else {
                    throw error
                }
            }
        }
        
        func fetchListings(neighborhoods: String, pageSize: Int) async -> Result<String, Error> {
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
        
#if os(Linux)
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
                
                // Selects `qr-card-property` elements, which are the main containers for each listing item.
                // Each `qr-card-property` contains:
                //      <a>: the first child link with the listing URL
                //      <div.card-remax>: contains detailed listing information.
                // This approach ensures we capture the essential data for constructing Listing objects.
                let qrCardPropertyElements = try document.select("qr-card-property")
                for qrCardProperty in qrCardPropertyElements.array() {
                    if let linkNode = try qrCardProperty.select("a").first(),
                       let detailsNode = try qrCardProperty.select("div.card-remax").last() {
                        let href: String = try linkNode.attr("href")
                        let listing = try createListingItem(from: detailsNode, with: href)
                        extractedListings.append(listing)
                    }
                }
            } catch {
                print("Error extracting listings: \(error)")
            }

            return extractedListings
        }
        
        fileprivate func createListingItem(from element: Element, with link: String) throws -> Listing {
            let link = "http://www.remax.com.ar" + link
            
            let addressSelector = """
                                  div.card-remax__container
                                  div.card__ubication-and-address
                                  p.card__address
                                  """
            let priceSelector = """
                                div.card-remax__container
                                div.card__header
                                div.card__price-and-expenses
                                p.card__price
                                """
            let expensesSelector = """
                                   div.card-remax__container
                                   div.card__header
                                   div.card__price-and-expenses
                                   p.card__expenses
                                   """
            let descriptionSelector = """
                                      div.card-remax__container
                                      div.card__description-and-brokers
                                      p.card__description
                                      """
            let totalAreaSelector = """
                                    div.card-remax__container
                                    div.card__feature
                                    div.card__m2total-and-m2cover
                                    div.card__feature--item.feature--m2total
                                    span
                                    """
            let coveredAreaSelector = """
                                      div.card-remax__container
                                      div.card__feature
                                      div.card__m2total-and-m2cover
                                      div.card__feature--item.feature--m2cover
                                      span
                                      """
            let roomsSelector = """
                                div.card-remax__container
                                div.card__feature
                                div.card__rooms-and-bathroom-and-units
                                div.card__feature--item.feature--ambientes
                                span
                                """
            let bathroomsSelector = """
                                    div.card-remax__container
                                    div.card__feature
                                    div.card__rooms-and-bathroom-and-units
                                    div.card__feature--item.feature--bathroom
                                    span
                                    """

            let address = try element.select(addressSelector).text()
            let priceText = try element.select(priceSelector).text()
            let expensesText = try element.select(expensesSelector).text()
            // Extracting numeric values only for price and expenses
            let price = priceText.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            let expenses = expensesText.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            let description = try element.select(descriptionSelector).text()
            let totalArea = try element.select(totalAreaSelector).text()
            let coveredArea = try element.select(coveredAreaSelector).text()
            let rooms = try element.select(roomsSelector).text()
            let bathrooms = try element.select(bathroomsSelector).text()

            return Listing(
                link: link,
                address: address,
                price: price,
                expenses: expenses,
                description: description,
                totalArea: totalArea,
                coveredArea: coveredArea,
                rooms: rooms,
                bathrooms: bathrooms
            )
        }
    }
}
