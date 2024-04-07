import Foundation
import GRDB

// Query ==============
struct ApiQueryResponse: Codable {
    let page: QueryResponseData
    let code: Int
    let message: String
    let errors: [String]?
    
    private enum CodingKeys: String, CodingKey {
        case page = "data"
        case code, message, errors
    }
}

struct QueryResponseData: Codable {
    let slugs: [ListingSlug]
    
    private enum CodingKeys: String, CodingKey {
        case slugs = "data"
    }
}

public struct ListingSlug: Codable {
    let value: String
    private enum CodingKeys: String, CodingKey {
        case value = "slug"
    }
}

// Response ==============
struct ListingDetailsResponse: Codable {
    let data: ListingDetail
    let code: Int
    let message: String
    let errors: [String]?
}

struct Location: Codable {
    let type: String
    let coordinates: [Double]
}

struct Currency: Codable {
    let id: Int
    let value: String
}

struct Associate: Codable {
    let id: String
    let officeId: String
    let office: Office
    let name: String
    let slug: String
    let title: String
    let biography: String?
    let photo: String?
//    let rawPhoto: String?
    let phones: [Phone]
    let emails: [Email]
    let auctioneerOffice: Bool
    let auctioneerAssociate: Bool
    let license: String?
    let internalId: String
    let role: String
    
    private enum CodingKeys: String, CodingKey {
        case id, officeId, office, name, slug, title, biography, photo, phones, emails, auctioneerOffice,
             auctioneerAssociate, license, internalId, role/*, rawPhoto*/
    }
}

struct PropertyType: Codable {
    let id: Int
    let value: String
}

struct Operation: Codable {
    let id: Int
    let value: String
}

struct ListingStatus: Codable {
    let id: Int
    let value: String
}

struct Opportunity: Codable {
    let id: Int
    let value: String
}

struct Photo: Codable {
    let value: String
    let position: Int
    // other properties as needed
}

struct Condition: Codable {
    let id: Int
    let value: String
}

struct Feature: Codable {
    // TODO: Find which values might go here
    // Define according to JSON structure
}

struct VirtualTour: Codable {
    // TODO: Find which values might go here
    // Define according to JSON structure
}

struct Geo: Codable {
    let id: Int
    let rootLabel: String
    let state: String
    let subregion: String?
    let countie: String?
    let citie: String
    let neighborhood: String?
    let privatecommunitie: String?
    let label: String
    let slug: String
    let rootCount: Int
    let level: Int
    let stateId: String
    let subregionId: String?
    let countyId: Int
    let cityId: Int
    let neighborhoodId: Int
    let privatecommunityId: Int
    
    private enum CodingKeys: String, CodingKey {
        case id
        case rootLabel = "rootLabel"
        case state
        case subregion
        case countie
        case citie = "citie"
        case neighborhood
        case privatecommunitie = "privatecommunitie"
        case label
        case slug
        case rootCount = "rootCount"
        case level
        case stateId = "stateId"
        case subregionId
        case countyId = "countyId"
        case cityId = "cityId"
        case neighborhoodId = "neighborhoodId"
        case privatecommunityId = "privatecommunityId"
    }
}

struct Broker: Codable {
    let id: String
    let officeId: String
    let office: Office
    let name: String
    let slug: String
    let title: String
    let biography: String?
    let photo: String?
//    let rawPhoto: String?
    let phones: [Phone]
    let emails: [Email]
    let auctioneerOffice: Bool
    let auctioneerAssociate: Bool
    let license: String
    let internalId: String
    let role: String
    
    private enum CodingKeys: String, CodingKey {
        case id, officeId, office, name, slug, title, biography, photo, /*rawPhoto,*/
             phones, emails, auctioneerOffice, auctioneerAssociate, license, internalId, role
    }
}

struct Office: Codable {
    let id: String
    let name: String
    let slug: String
    let description: String?
    let address: String
    let location: Location
    let emails: [Email]
    let phones: [Phone]
    let internalId: String
    let nodeId: String
    let photo: String?
//    let rawPhoto: String
    
    private enum CodingKeys: String, CodingKey {
        case id, name, slug, description, address, location, emails, phones, internalId, nodeId, photo/*, rawPhoto*/
    }
}

struct Email: Codable {
    let value: String
    let primary: Bool
}

struct Phone: Codable {
    let type: String
    let value: String
    let primary: Bool
}
