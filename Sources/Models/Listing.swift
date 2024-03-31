import GRDB

public struct Listing: Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var link: String
    var address: String
    var price: String
    var description: String
    var totalArea: String
    var coveredArea: String
    var rooms: String
    var bathrooms: String

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let link = Column(CodingKeys.link)
        static let address = Column(CodingKeys.address)
        static let price = Column(CodingKeys.price)
        static let description = Column(CodingKeys.description)
        static let totalArea = Column(CodingKeys.totalArea)
        static let coveredArea = Column(CodingKeys.coveredArea)
        static let rooms = Column(CodingKeys.rooms)
        static let bathrooms = Column(CodingKeys.bathrooms)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case link
        case address
        case price
        case description
        case totalArea
        case coveredArea
        case rooms
        case bathrooms
    }

    // Implement the database methods for fetching and persisting records as needed
}
