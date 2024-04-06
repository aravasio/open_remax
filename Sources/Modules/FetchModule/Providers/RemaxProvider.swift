import Foundation
import NIO
import AsyncHTTPClient
import SwiftSoup
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

fileprivate protocol ServiceProvider {
    func fetchListingsResults(neighborhoods: String, pageSize: Int) async -> Result<String, Error>
    func extractDetailsURL(from htmlString: String) -> [URL]
//    func extractListings(from htmlString: String) throws -> Listing
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
        
        func fetch(retryCount: Int = 0) async throws -> [Listing] {
            let result: Result<String, Error> = await fetchListingsResults(neighborhoods: neighborhoods, pageSize: pageSize)
            
            switch result {
            case let .success(htmlString):
                let urls: [URL] = extractDetailsURL(from: htmlString)
                var listings: [Listing] = []
                
                for url in urls {
                    let detailsHTML: String = try String(contentsOf: url, encoding: .utf8)
                    let listing = try extractListings(from: detailsHTML, using: url)
                }
                
                return listings
                
            case let .failure(error):
                if retryCount < retryTolerance {
                    return try await fetch(retryCount: retryCount + 1)
                } else {
                    throw error
                }
            }
        }
        
        func fetchListingsResults(neighborhoods: String, pageSize: Int) async -> Result<String, Error> {
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
#elseif os(Linux)
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
        
        func extractDetailsURL(from htmlString: String) -> [URL] {
            var urls: [URL] = []
            do {
                let document: Document = try SwiftSoup.parse(htmlString)
                
                // Selects `qr-card-property` elements, which are the main containers for each listing item.
                // Each `qr-card-property` contains:
                //      <a>: the first child link with the listing URL
                // This approach ensures we capture the essential data for constructing Listing objects.
                let qrCardPropertyElements = try document.select("qr-card-property")
                for qrCardProperty in qrCardPropertyElements.array() {
                    if let linkNode = try qrCardProperty.select("a").first() {
                        let href: String = try linkNode.attr("href")
                        if let url = URL(string: "http://www.remax.com.ar" + href) {
                            urls.append(url)
                        }
                    }
                }
            } catch {
                print("Error extracting listings: \(error)")
            }
            
            return urls
        }
                
        func extractListings(from htmlString: String, using url: URL) throws -> Listing? {
            let doc = try SwiftSoup.parse(htmlString)
            
            let price = try extractPrice(from: doc)
            let details = try extractCardDetails(from: doc)
            
            guard let address = try doc.select("div#card-map div#content p#ubication-text").first()?.text() else {
                throw ApartmentListingError.parsingFailed(reason: "Root element 'div#card-map div#content p#ubication-text' not found")
            }
            
            let mapCoordinatesNode = try doc.select("div#card-map div#map div#map-wrapper img").attr("abs:src")
            guard !mapCoordinatesNode.isEmpty else {
                throw ApartmentListingError.parsingFailed(reason: "Map image src not found")
            }
            
            let coordinates = try extractCoordinates(from: mapCoordinatesNode)
            
            return Listing(
                link: url.absoluteString,
                address: address,
                price: price,
                expenses: details.expenses,
                description: details.description,
                totalArea: details.totalSurfaceArea,
                coveredArea: details.coveredSurfaceArea,
                rooms: details.rooms,
                bathrooms: details.bathrooms,
                toilettes: details.toilettes,
                bedrooms: details.bedrooms,
                garage: details.garage,
                antiquity: details.antiquity,
                suitableForCredit: details.suitableForCredit,
                offersFinancing: details.offersFinancing,
                floorsInTheProperty: details.floorsInTheProperty
            )
        }
        
        func extractPrice(from doc: Document) throws -> String {
            guard let priceText = try doc.select("qr-card-info-prop div#container div.ng-star-inserted div#price-container p").first()?.text() else {
                throw ApartmentListingError.parsingFailed(reason: "Price text not found")
            }
            return priceText
        }
        
        fileprivate func extractCoordinates(from src: String) throws -> (latitude: String, longitude: String) {
            guard let url = URL(string: src),
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                  let queryItems = components.queryItems else {
                throw ApartmentListingError.parsingFailed(reason: "Failed to parse URL or query items")
            }
            
            for item in queryItems {
                if item.name == "markers", let value = item.value {
                    // Expecting value format to be "color:red|latitude,longitude"
                    let markerComponents = value.components(separatedBy: "|").last
                    let coordinates = markerComponents?.split(separator: ",").map(String.init)
                    if let latitude = coordinates?.first,
                       let longitude = coordinates?.last {
                        return (latitude, longitude)
                    } else {
                        throw ApartmentListingError.parsingFailed(reason: "Coordinates not found or invalid")
                    }
                }
            }
            
            throw ApartmentListingError.parsingFailed(reason: "Markers query item not found")
        }
        
        fileprivate func extractCardDetails(from doc: Document) throws -> ExtractedDetails {
            //extract details from qr-card-details-prop
            guard let element = try doc.select("qr-card-details-prop").first() else {
                throw ApartmentListingError.parsingFailed(reason: "Root element 'qr-card-details-prop' not found")
            }
            
            guard let description = try element.select("div#title h3#last").first()?.text() else {
                throw ApartmentListingError.parsingFailed(reason: "Description not found")
            }
            
            // Attempt to extract other required fields in a similar manner, throwing an error if any are not found
            let totalSurfaceArea = try findOrThrow(element, selector: "span.feature-detail:contains(superficie total)", errorReason: "Total Surface Area not found")
            let coveredSurfaceArea = try findOrThrow(element, selector: "span.feature-detail:contains(superficie cubierta)", errorReason: "Covered Surface Area not found")
            let semiCoveredSurfaceArea = try findOrThrow(element, selector: "span.feature-detail:contains(superficie semicubierta)", errorReason: "Semi-Covered Surface Area not found")
            let rooms = try findOrThrow(element, selector: "span.feature-detail:contains(ambientes)", errorReason: "Rooms not found")
            let bathrooms = try findOrThrow(element, selector: "span.feature-detail:contains(baños)", errorReason: "Bathrooms not found")
            let toilettes = try findOrThrow(element, selector: "span.feature-detail:contains(toilets)", errorReason: "Toilettes not found")
            let bedrooms = try findOrThrow(element, selector: "span.feature-detail:contains(dormitorios)", errorReason: "Bedrooms not found")
            let garage = try findOrThrow(element, selector: "span.feature-detail:contains(cocheras)", errorReason: "Garage not found")
            let antiquity = try findOrThrow(element, selector: "div#antiquity span", errorReason: "Antiquity not found")
            let expenses = try findOrThrow(element, selector: "span.feature-detail:contains(expensas)", errorReason: "Expenses not found")
            let suitableForCredit = try findOrThrow(element, selector: "span.feature-detail:contains(Apto credito)", errorReason: "Suitable for Credit not found")
            let offersFinancing = try findOrThrow(element, selector: "span.feature-detail:contains(ofrece financiamiento)", errorReason: "Offers Financing not found")
            let floorsInTheProperty = try findOrThrow(element, selector: "span.feature-detail:contains(pisos de la propiedad)", errorReason: "Floors in the Property not found")
            
            return ExtractedDetails(description, totalSurfaceArea, coveredSurfaceArea, semiCoveredSurfaceArea, rooms,
                                    bathrooms, toilettes, bedrooms, garage, antiquity, expenses,
                                    suitableForCredit, offersFinancing, floorsInTheProperty)
            
        }
        
        // Helper function to attempt finding an element with a specific selector, throwing an error if not found
        func findOrThrow(_ root: Element, selector: String, errorReason: String) throws -> String {
            guard let text = try root.select(selector).first()?.text(), !text.isEmpty else {
                throw ApartmentListingError.parsingFailed(reason: errorReason)
            }
            return text
        }
        
        fileprivate typealias Address = (name: String, longitude: String, altitude: String)
        fileprivate typealias ExtractedDetails = (
            description: String, totalSurfaceArea: String, coveredSurfaceArea: String, semiCoveredSurfaceArea: String,
            rooms: String, bathrooms: String, toilettes: String, bedrooms: String, garage: String, antiquity: String,
            expenses: String, suitableForCredit: String, offersFinancing: String, floorsInTheProperty: String
        )
    }
}

