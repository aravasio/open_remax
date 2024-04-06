import GRDB

public struct Listing: Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var link: String
    var address: String
    var price: String
    var expenses: String
    var description: String
    var totalArea: String
    var coveredArea: String
    var rooms: String
    var bathrooms: String
    var toilettes: String // New field if applicable
    var bedrooms: String // New field if applicable
    var garage: String // New field if applicable
    var antiquity: String // New field if applicable
    var suitableForCredit: String // New field if applicable
    var offersFinancing: String // New field if applicable
    var floorsInTheProperty: String // New field if applicable
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let link = Column(CodingKeys.link)
        static let address = Column(CodingKeys.address)
        static let price = Column(CodingKeys.price)
        static let expenses = Column(CodingKeys.expenses)
        static let description = Column(CodingKeys.description)
        static let totalArea = Column(CodingKeys.totalArea)
        static let coveredArea = Column(CodingKeys.coveredArea)
        static let rooms = Column(CodingKeys.rooms)
        static let bathrooms = Column(CodingKeys.bathrooms)
        static let toilettes = Column(CodingKeys.toilettes) // New column if applicable
        static let bedrooms = Column(CodingKeys.bedrooms) // New column if applicable
        static let garage = Column(CodingKeys.garage) // New column if applicable
        static let antiquity = Column(CodingKeys.antiquity) // New column if applicable
        static let suitableForCredit = Column(CodingKeys.suitableForCredit) // New column if applicable
        static let offersFinancing = Column(CodingKeys.offersFinancing) // New column if applicable
        static let floorsInTheProperty = Column(CodingKeys.floorsInTheProperty) // New column if applicable
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case link
        case address
        case price
        case expenses
        case description
        case totalArea
        case coveredArea
        case rooms
        case bathrooms
        case toilettes // New field if applicable
        case bedrooms // New field if applicable
        case garage // New field if applicable
        case antiquity // New field if applicable
        case suitableForCredit // New field if applicable
        case offersFinancing // New field if applicable
        case floorsInTheProperty // New field if applicable
    }
    
    // Implementation for FetchableRecord and MutablePersistableRecord if necessary...
}
