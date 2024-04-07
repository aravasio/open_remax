import GRDB

public struct ListingDetail: Codable {
    let id: String
    let title: String
    let slug: String
    let description: String
    let location: Location
    
    let totalRooms: Int
    let bedrooms: Int
    let bathrooms: Int
    let toilets: Int
    let floors: Int
    let pozo: Bool
    let parkingSpaces: Int
//    let video: String
    let yearBuilt: Int?
    let price: Double?
    let priceExposure: Bool
    let currency: Currency
    let expensesPrice: Double?
    let expensesCurrency: Currency
    let professionalUse: Bool
    let commercialUse: Bool
    let remaxCollection: Bool
    let financing: Bool
    let aptCredit: Bool
    let reducedMovility: Bool
    let inPrivateCommunity: Bool
    let internalId: String
    let displayAddress: String
    let dimensionLand: Double
    let dimensionTotalBuilt: Double
    let dimensionCovered: Double
    let dimensionUncovered: Double
    let dimensionSemicovered: Double
    let associate: Associate
    let type: PropertyType
    let operation: Operation
    let listingStatus: ListingStatus
    let opportunity: Opportunity
    let photos: [Photo]
    let conditions: [Condition]
    let features: [Feature]
    let virtualTours: [VirtualTour]
    let listBroker: [Broker]
    let geo: Geo
    let showLendarBanner: Bool
    let quotes: Int
    let feeQuotes: Double
    let favorite: Bool
}

extension ListingDetail {
    private enum CodingKeys: String, CodingKey {
        case opportunity = "oportunity"
        case id, title, slug, description, location, totalRooms, bedrooms, bathrooms, toilets, floors, pozo, parkingSpaces, yearBuilt, price, priceExposure, currency, expensesPrice, expensesCurrency, professionalUse, commercialUse, remaxCollection, financing, aptCredit, reducedMovility, inPrivateCommunity, internalId, displayAddress, dimensionLand, dimensionTotalBuilt, dimensionCovered, dimensionUncovered, dimensionSemicovered, associate, type, operation, listingStatus, photos, conditions, features, virtualTours, listBroker, geo, showLendarBanner, quotes, feeQuotes, favorite
    }
}

extension ListingDetail: FetchableRecord, PersistableRecord {
    public static var databaseTableName: String { "listing" }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let title = Column(CodingKeys.title)
        static let slug = Column(CodingKeys.slug)
        static let description = Column(CodingKeys.description)
        static let location = Column(CodingKeys.location)
        static let totalRooms = Column(CodingKeys.totalRooms)
        static let bedrooms = Column(CodingKeys.bedrooms)
        static let bathrooms = Column(CodingKeys.bathrooms)
        static let toilets = Column(CodingKeys.toilets)
        static let floors = Column(CodingKeys.floors)
        static let pozo = Column(CodingKeys.pozo)
        static let parkingSpaces = Column(CodingKeys.parkingSpaces)
//        static let video = Column(CodingKeys.video)
        static let yearBuilt = Column(CodingKeys.yearBuilt)
        static let price = Column(CodingKeys.price)
        static let priceExposure = Column(CodingKeys.priceExposure)
        static let currency = Column(CodingKeys.currency)
        static let expensesPrice = Column(CodingKeys.expensesPrice)
        static let expensesCurrency = Column(CodingKeys.expensesCurrency)
        static let professionalUse = Column(CodingKeys.professionalUse)
        static let commercialUse = Column(CodingKeys.commercialUse)
        static let remaxCollection = Column(CodingKeys.remaxCollection)
        static let financing = Column(CodingKeys.financing)
        static let aptCredit = Column(CodingKeys.aptCredit)
        static let reducedMovility = Column(CodingKeys.reducedMovility)
        static let inPrivateCommunity = Column(CodingKeys.inPrivateCommunity)
        static let internalId = Column(CodingKeys.internalId)
        static let displayAddress = Column(CodingKeys.displayAddress)
        static let dimensionLand = Column(CodingKeys.dimensionLand)
        static let dimensionTotalBuilt = Column(CodingKeys.dimensionTotalBuilt)
        static let dimensionCovered = Column(CodingKeys.dimensionCovered)
        static let dimensionUncovered = Column(CodingKeys.dimensionUncovered)
        static let dimensionSemicovered = Column(CodingKeys.dimensionSemicovered)
        static let associate = Column(CodingKeys.associate)
        static let type = Column(CodingKeys.type)
        static let operation = Column(CodingKeys.operation)
        static let listingStatus = Column(CodingKeys.listingStatus)
        static let opportunity = Column(CodingKeys.opportunity)
        static let photos = Column(CodingKeys.photos)
        static let conditions = Column(CodingKeys.conditions)
        static let features = Column(CodingKeys.features)
//        static let virtualTours = Column(CodingKeys.virtualTours)
        static let listBroker = Column(CodingKeys.listBroker)
        static let geo = Column(CodingKeys.geo)
        static let quotes = Column(CodingKeys.quotes)
        static let feeQuotes = Column(CodingKeys.feeQuotes)
    }
    
    public func encode(to container: inout PersistenceContainer) throws {
        container["id"] = id
        container["title"] = title
        container["slug"] = slug
        container["description"] = description
        container["location_altitude"] = location.coordinates[0]
        container["location_latitude"] = location.coordinates[1]
        //
        container["total_rooms"] = totalRooms
        container["bedrooms"] = bedrooms
        container["bathrooms"] = bathrooms
        container["toilets"] = toilets
        container["floors"] = floors
        container["pozo"] = pozo
        container["parking_spaces"] = parkingSpaces
        //        container["video"] = video
        container["year_built"] = yearBuilt
        container["price"] = price
        container["price_exposure"] = priceExposure
        container["currency"] = currency.value
        container["expenses_price"] = expensesPrice
        container["expenses_currency"] = expensesCurrency.value
        container["apt_professional_use"] = professionalUse
        container["apt_commercial_use"] = commercialUse
        container["remax_collection"] = remaxCollection
        container["offers_financing"] = financing
        container["apt_credit"] = aptCredit
        container["in_private_community"] = inPrivateCommunity
        container["internal_id"] = internalId
        container["display_address"] = displayAddress
        container["total_squared_meters"] = dimensionLand
        container["total_area_built"] = dimensionTotalBuilt
        container["total_squared_meters_covered"] = dimensionCovered
        container["total_squared_meters_semicovered"] = dimensionSemicovered
        container["total_squared_meters_uncovered"] = dimensionUncovered
        container["quotes"] = quotes
        container["fee_quotes"] = feeQuotes
    }
}
