import Foundation
import NIO
import AsyncHTTPClient
import SwiftSoup
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

fileprivate protocol ServiceProvider {
    func fetch(retryCount: Int) async throws -> [Listing]
//    func fetchListingsResults(neighborhoods: String, pageSize: Int) async -> Result<String, Error>
    func extractDetailsURL(from htmlString: String) -> [URL]
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
        
        private let pageSize: Int = 5
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
                    listings.append(listing)
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
        
        fileprivate func extractDetailsURL(from htmlString: String) -> [URL] {
            var urls: [URL] = []
            do {
                let document: Document = try SwiftSoup.parse(htmlString)
                // Adjusted selector to match the provided hierarchy more closely
                let linkElements = try document.select("app-layout mat-sidenav-container mat-sidenav-content div.main-content div.page-content app-list div div.container qr-card-property a")
                
                for element in linkElements.array() {
                    let href: String = try element.attr("href")
                    // Ensure the URL is complete; adjust the base URL if necessary
                    if let url = URL(string: "https://www.remax.com.ar" + href) {
                        urls.append(url)
                    }
                }
            } catch {
                print("Error extracting listings: \(error)")
            }
            
            return urls
        }

        fileprivate func extractListings(from htmlString: String, using url: URL) throws -> Listing {
            let doc = try SwiftSoup.parse(htmlString)
            
            let price = try extractPrice(from: doc)
            let details = try extractCardDetails(from: doc)
            
            guard let address = try doc.select(HTMLSelectors.Details.ubicationText).first()?.text() else {
                throw ApartmentListingError.parsingFailed(reason: HTMLSelectors.Errors.ubicationTextNotFound)
            }
            
            let mapCoordinatesNode = try doc.select(HTMLSelectors.Details.mapImageSrc).attr("abs:src")
            guard !mapCoordinatesNode.isEmpty else {
                throw ApartmentListingError.parsingFailed(reason: HTMLSelectors.Errors.mapImageSrcNotFound)
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
        
        
        fileprivate func extractPrice(from doc: Document) throws -> String {
            guard let priceText = try doc.select(HTMLSelectors.Details.price).first()?.text() else {
                throw ApartmentListingError.parsingFailed(reason: HTMLSelectors.Errors.priceNotFound)
            }
            return priceText
        }
        
        fileprivate func extractCoordinates(from src: String) throws -> (latitude: String, longitude: String) {
            guard let url = URL(string: src),
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                  let queryItems = components.queryItems else {
                throw ApartmentListingError.parsingFailed(reason: "Failed to parse URL or query items")
            }
            
            guard let markersValue = queryItems.first(where: { $0.name == HTMLSelectors.URLParameters.markers })?.value
            else { throw ApartmentListingError.parsingFailed(reason: HTMLSelectors.Errors.markersNotFound) }
            
            let markerComponents = markersValue.components(separatedBy: "|").last
            let coordinates = markerComponents?.split(separator: ",").map(String.init)
            
            guard let latitude = coordinates?.first, let longitude = coordinates?.last
            else { throw ApartmentListingError.parsingFailed(reason: HTMLSelectors.Errors.coordinatesInvalid) }
            
            return (latitude, longitude)
        }
        
        fileprivate func extractCardDetails(from doc: Document) throws -> ExtractedDetails {
            guard let element = try doc.select(HTMLSelectors.Details.detailsProp).first() else {
                throw ApartmentListingError.parsingFailed(reason: HTMLSelectors.Errors.rootNotFound)
            }
            
            let description = try findOrThrow(
                element,
                selector: HTMLSelectors.Details.description,
                errorReason: HTMLSelectors.Errors.descriptionNotFound)
            let totalSurfaceAreaError = String(format: HTMLSelectors.Errors.detailNotFoundFormat, "Total Surface Area")
            let totalSurfaceArea = try findOrThrow(
                element,
                selector: HTMLSelectors.Details.totalPrice,
                errorReason: totalSurfaceAreaError)
            let coveredSurfaceArea = try findOrThrow(
                element,
                selector: HTMLSelectors.Details.coveredArea,
                errorReason: String(format: HTMLSelectors.Errors.detailNotFoundFormat, "Covered Surface Area"))
            let semiCoveredSurfaceArea = try findOrThrow(
                element,
                selector: HTMLSelectors.Details.semiCoveredArea,
                errorReason: String(format: HTMLSelectors.Errors.detailNotFoundFormat, "Semi-Covered Surface Area"))
            let rooms = try findOrThrow(
                element,
                selector: HTMLSelectors.Details.rooms,
                errorReason: String(format: HTMLSelectors.Errors.detailNotFoundFormat, "Rooms"))
            let bathrooms = try findOrThrow(
                element,
                selector: HTMLSelectors.Details.bathrooms,
                errorReason: String(format: HTMLSelectors.Errors.detailNotFoundFormat, "Bathrooms"))
            let toilettes = try findOrThrow(
                element,
                selector: HTMLSelectors.Details.toilets,
                errorReason: String(format: HTMLSelectors.Errors.detailNotFoundFormat, "Toilettes"))
            let bedrooms = try findOrThrow(
                element,
                selector: HTMLSelectors.Details.bedrooms,
                errorReason: String(format: HTMLSelectors.Errors.detailNotFoundFormat, "Bedrooms"))
            let garage = try findOrThrow(
                element,
                selector: HTMLSelectors.Details.garage,
                errorReason: String(format: HTMLSelectors.Errors.detailNotFoundFormat, "Garage"))
            let antiquity = try findOrThrow(
                element,
                selector: HTMLSelectors.Details.antiquity,
                errorReason: String(format: HTMLSelectors.Errors.detailNotFoundFormat, "Antiquity"))
            let expenses = try findOrThrow(
                element,
                selector: HTMLSelectors.Details.expenses,
                errorReason: String(format: HTMLSelectors.Errors.detailNotFoundFormat, "Expenses"))
            let suitableForCredit = try findOrThrow(
                element,
                selector: HTMLSelectors.Details.suitableForCredit,
                errorReason: String(format: HTMLSelectors.Errors.detailNotFoundFormat, "Suitable for Credit"))
            let offersFinancing = try findOrThrow(
                element,
                selector: HTMLSelectors.Details.offersFinancing,
                errorReason: String(format: HTMLSelectors.Errors.detailNotFoundFormat, "Offers Financing"))
            let floorsInTheProperty = try findOrThrow(
                element,
                selector: HTMLSelectors.Details.floorsInTheProperty,
                errorReason: String(format: HTMLSelectors.Errors.detailNotFoundFormat, "Floors in the Property"))
            
            return ExtractedDetails(
                description: description,
                totalSurfaceArea: totalSurfaceArea,
                coveredSurfaceArea: coveredSurfaceArea,
                semiCoveredSurfaceArea: semiCoveredSurfaceArea,
                rooms: rooms,
                bathrooms: bathrooms,
                toilettes: toilettes,
                bedrooms: bedrooms,
                garage: garage,
                antiquity: antiquity,
                expenses: expenses,
                suitableForCredit: suitableForCredit,
                offersFinancing: offersFinancing,
                floorsInTheProperty: floorsInTheProperty
            )
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

fileprivate struct HTMLSelectors {
    enum Details {
        static let qrCardProperty = "qr-card-property a"
        static let price = "qr-card-info-prop div#container div.ng-star-inserted div#price-container p"
        static let detailsProp = "qr-card-details-prop"
        static let description = "div#title h3#last"
        static let totalPrice = "span.feature-detail:contains(superficie total)"
        static let coveredArea = "span.feature-detail:contains(superficie cubierta)"
        static let semiCoveredArea = "span.feature-detail:contains(superficie semicubierta)"
        static let rooms = "span.feature-detail:contains(ambientes)"
        static let bathrooms = "span.feature-detail:contains(baños)"
        static let toilets = "span.feature-detail:contains(toilets)"
        static let bedrooms = "span.feature-detail:contains(dormitorios)"
        static let garage = "span.feature-detail:contains(cocheras)"
        static let antiquity = "div#antiquity span"
        static let expenses = "span.feature-detail:contains(expensas)"
        static let suitableForCredit = "span.feature-detail:contains(Apto credito)"
        static let offersFinancing = "span.feature-detail:contains(ofrece financiamiento)"
        static let floorsInTheProperty = "span.feature-detail:contains(pisos de la propiedad)"
        static let ubicationText = "div#card-map div#content p#ubication-text"
        static let mapImageSrc = "div#card-map div#map div#map-wrapper img"
    }
    
    enum URLParameters {
        static let markers = "markers"
    }
    
    enum Errors {
        static let priceNotFound = "Price text not found"
        static let markersNotFound = "Markers query item not found"
        static let coordinatesInvalid = "Coordinates not found or invalid"
        static let rootNotFound = "Root element 'qr-card-details-prop' not found"
        static let descriptionNotFound = "Description not found"
        static let detailNotFoundFormat = "%@ not found"
        static let ubicationTextNotFound = "Root element 'div#card-map div#content p#ubication-text' not found"
        static let mapImageSrcNotFound = "Map image src not found"
    }
}
