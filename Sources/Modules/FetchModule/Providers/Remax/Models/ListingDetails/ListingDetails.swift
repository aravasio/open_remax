import GRDB

public struct ListingDetail: Codable {
    // Basic Details
    let id: String
    let internalId: String
    let title: String
    let slug: String
    let description: String
    let displayAddress: String
    
    // Location and Mapping
    let location: Location // Contains altitude and latitude
    
    // Property Details
    let totalRooms: Int
    let bedrooms: Int
    let bathrooms: Int
    let toilets: Int
    let floors: Int
    
    // Property Features
    let pozo: Bool
    let parkingSpaces: Int
    let professionalUse: Bool
    let commercialUse: Bool
    let inPrivateCommunity: Bool
    let reducedMovility: Bool
    let financing: Bool
    let aptCredit: Bool
    
    // Financial Detail
    let price: Double? // IIRC: If it's nil, it's because there're non-numerical values, i.e. 'consultar-precio'.
    let currency: Currency
    let expensesPrice: Double?
    let expensesCurrency: Currency?
    let priceExposure: Bool
    let feeQuotes: Double
    
    // Property Dimensions
    let dimensionLand: Double
    let dimensionTotalBuilt: Double
    let dimensionCovered: Double
    let dimensionSemicovered: Double
    let dimensionUncovered: Double
    
    // Additional Information
    let yearBuilt: Int?
    let quotes: Int
    let video: String
    let conditions: [Condition]
    let type: PropertyType
    let operation: Operation
    let listingStatus: ListingStatus
    let photos: [Photo]
    let features: [Feature]
    let opportunity: Opportunity
    
    //TODO: Pending properties
    // let showLendarBanner: Bool
    // let virtualTours: [VirtualTour]
    // let geo: Geo
    
    private enum CodingKeys: String, CodingKey {
        case opportunity = "oportunity"
        case id, internalId, title, slug, description, displayAddress, location,
             totalRooms, bedrooms, bathrooms, toilets, floors, pozo, parkingSpaces,
             professionalUse, commercialUse, inPrivateCommunity, reducedMovility,
             financing, aptCredit, price, currency, expensesPrice, expensesCurrency,
             priceExposure, feeQuotes, dimensionLand, dimensionTotalBuilt,
             dimensionCovered, dimensionSemicovered, dimensionUncovered,
             yearBuilt, quotes, video, conditions, type, operation, listingStatus,
             photos, features
    }
}

extension ListingDetail: PersistableRecord {
    public static var databaseTableName: String { "listing" }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let internalId = Column("internal_id")
        static let title = Column(CodingKeys.title)
        static let slug = Column(CodingKeys.slug)
        static let description = Column(CodingKeys.description)
        static let displayAddress = Column("display_address")
        static let location_altitude = Column("location_altitude")
        static let location_latitude = Column("location_latitude")
        static let totalRooms = Column("total_rooms")
        static let bedrooms = Column(CodingKeys.bedrooms)
        static let bathrooms = Column(CodingKeys.bathrooms)
        static let toilets = Column(CodingKeys.toilets)
        static let floors = Column(CodingKeys.floors)
        static let pozo = Column(CodingKeys.pozo)
        static let parkingSpaces = Column("parking_spaces")
        static let professionalUse = Column("apt_professional_use")
        static let commercialUse = Column("apt_commercial_use")
        static let inPrivateCommunity = Column("in_private_community")
        static let reducedMovility = Column("reduced_mobility_compliant")
        static let financing = Column("offers_financing")
        static let aptCredit = Column("apt_credit")
        static let price = Column(CodingKeys.price)
        static let currency = Column(CodingKeys.currency)
        static let expensesPrice = Column("expenses_price")
        static let expensesCurrency = Column("expenses_currency")
        static let priceExposure = Column("price_exposure")
        static let feeQuotes = Column("fee_quote")
        static let dimensionLand = Column("total_lot_size")
        static let dimensionTotalBuilt = Column("total_area_built")
        static let dimensionCovered = Column("total_squared_meters_covered")
        static let dimensionSemicovered = Column("total_squared_meters_semicovered")
        static let dimensionUncovered = Column("total_squared_meters_uncovered")
        static let yearBuilt = Column("year_built")
        static let quotes = Column(CodingKeys.quotes)
        static let video = Column(CodingKeys.video)
        static let conditions = Column(CodingKeys.conditions)
        static let type = Column(CodingKeys.type)
        static let operation = Column(CodingKeys.operation)
        static let listingStatus = Column("listing_status")
        static let photos = Column(CodingKeys.photos)
        static let features = Column(CodingKeys.features)
        static let opportunity = Column("opportunity")
    }
    
    public func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.internalId] = internalId
        container[Columns.title] = title
        container[Columns.slug] = slug
        container[Columns.description] = description
        container[Columns.displayAddress] = displayAddress
        container[Columns.location_altitude] = location.coordinates[0]
        container[Columns.location_latitude] = location.coordinates[1]
        container[Columns.totalRooms] = totalRooms
        container[Columns.bedrooms] = bedrooms
        container[Columns.bathrooms] = bathrooms
        container[Columns.toilets] = toilets
        container[Columns.floors] = floors
        container[Columns.pozo] = pozo
        container[Columns.parkingSpaces] = parkingSpaces
        container[Columns.professionalUse] = professionalUse
        container[Columns.commercialUse] = commercialUse
        container[Columns.inPrivateCommunity] = inPrivateCommunity
        container[Columns.reducedMovility] = reducedMovility
        container[Columns.financing] = financing
        container[Columns.aptCredit] = aptCredit
        container[Columns.price] = price
        container[Columns.currency] = currency.value
        container[Columns.expensesPrice] = expensesPrice
        container[Columns.expensesCurrency] = expensesCurrency?.value
        container[Columns.priceExposure] = priceExposure
        container[Columns.feeQuotes] = feeQuotes
        container[Columns.dimensionLand] = dimensionLand
        container[Columns.dimensionTotalBuilt] = dimensionTotalBuilt
        container[Columns.dimensionCovered] = dimensionCovered
        container[Columns.dimensionSemicovered] = dimensionSemicovered
        container[Columns.dimensionUncovered] = dimensionUncovered
        container[Columns.yearBuilt] = yearBuilt
        container[Columns.quotes] = quotes
        container[Columns.video] = video
        container[Columns.conditions] = conditions.map { $0.value }.joined(separator: ",")
        container[Columns.type] = type.value
        container[Columns.operation] = operation.value
        container[Columns.listingStatus] = listingStatus.value
        container[Columns.photos] = photos.map { $0.value }.joined(separator: ",")
        container[Columns.features] = features.map { $0.value }.joined(separator: ",")
        container[Columns.opportunity] = opportunity.value
    }
}
