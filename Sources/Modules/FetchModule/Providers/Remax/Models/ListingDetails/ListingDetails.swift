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
    let yearBuilt: Int?
    let price: Double?
    let priceExposure: Bool
    let currency: Currency
    let expensesPrice: Double?
    let expensesCurrency: Currency
    let professionalUse: Bool
    let commercialUse: Bool
    let inPrivateCommunity: Bool
    let dimensionLand: Double
    let dimensionTotalBuilt: Double
    let dimensionCovered: Double
    let dimensionSemicovered: Double
    let dimensionUncovered: Double
    let quotes: Int
    let reducedMovility: Bool
    let internalId: String
    let financing: Bool
    let video: String
    let displayAddress: String
    let aptCredit: Bool
    let conditions: [Condition] // "Refaccionado", "excelente", etc. Each a tag.
    let type: PropertyType
    let operation: Operation
    let listingStatus: ListingStatus
    let photos: [Photo]
    let features: [Feature]
    let feeQuotes: Double
    let opportunity: Opportunity
    
    //TODO:
    //    let showLendarBanner: Bool // I think this is "show Lend-Ar(gentina) Banner", but not sure yet.
    //    let virtualTours: [VirtualTour] // Not sure what to expect for this property
    //    let geo: Geo // This has data like "capital federal", "colegiales",
    
    
    private enum CodingKeys: String, CodingKey {
        case opportunity = "oportunity"
        case id,
             title,
             slug,
             description,
             location,
             totalRooms,
             bedrooms,
             bathrooms,
             toilets,
             floors,
             pozo,
             parkingSpaces,
             yearBuilt,
             price,
             priceExposure,
             currency,
             expensesPrice,
             expensesCurrency,
             professionalUse,
             commercialUse,
             inPrivateCommunity,
             dimensionLand,
             dimensionTotalBuilt,
             dimensionCovered,
             dimensionUncovered,
             dimensionSemicovered,
             reducedMovility,
             quotes,
             internalId,
             financing,
             video,
             displayAddress,
             aptCredit,
             feeQuotes,
             conditions,
             type,
             operation,
             listingStatus,
             features,
             photos
    }
}

extension ListingDetail: PersistableRecord {
    public static var databaseTableName: String { "listing" }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let title = Column(CodingKeys.title)
        static let slug = Column(CodingKeys.slug)
        static let description = Column(CodingKeys.description)
        static let altitude = Column("location_altitude")
        static let latitude = Column("location_latitude")
        static let totalRooms = Column("total_rooms")
        static let bedrooms = Column(CodingKeys.bedrooms)
        static let bathrooms = Column(CodingKeys.bathrooms)
        static let toilets = Column(CodingKeys.toilets)
        static let floors = Column(CodingKeys.floors)
        static let pozo = Column(CodingKeys.pozo)
        static let parkingSpaces = Column("parking_spaces")
        static let video = Column(CodingKeys.video)
        static let yearBuilt = Column("year_built")
        static let price = Column(CodingKeys.price)
        static let priceExposure = Column("price_exposure")
        static let currency = Column(CodingKeys.currency)
        static let expensesPrice = Column("expenses_price")
        static let expensesCurrency = Column("expenses_currency")
        static let professionalUse = Column("professional_use")
        static let commercialUse = Column("commercial_use")
        static let financing = Column("offers_financing")
        static let aptCredit = Column("apt_credit")
        static let reducedMovility = Column("reduced_mobility_compliant")
        static let inPrivateCommunity = Column("in_private_community")
        static let internalId = Column("internal_id")
        static let displayAddress = Column("display_address")
        static let dimensionLand = Column("total_lot_size")
        static let dimensionTotalBuilt = Column("total_area_built")
        static let dimensionCovered = Column("total_squared_meters_covered")
        static let dimensionUncovered = Column("total_squared_meters_uncovered")
        static let dimensionSemicovered = Column("total_squared_meters_semicovered")
        static let type = Column(CodingKeys.type)
        static let operation = Column(CodingKeys.operation)
        static let listingStatus = Column("listing_status")
        static let conditions = Column(CodingKeys.conditions)
        static let features = Column(CodingKeys.features)
        static let quotes = Column(CodingKeys.quotes)
        static let feeQuotes = Column("fee_quotes")
        static let photos = Column(CodingKeys.photos)
        static let opportunity = Column("opportunity")
        //        static let virtualTours = Column(CodingKeys.virtualTours)
        //        static let geo = Column(CodingKeys.geo)
    }
    
    public func encode(to container: inout PersistenceContainer) throws {
        container["id"] = id
        container["title"] = title
        container["slug"] = slug
        container["description"] = description
        container["location_altitude"] = location.coordinates[0]
        container["location_latitude"] = location.coordinates[1]
        container["total_rooms"] = totalRooms
        container["bedrooms"] = bedrooms
        container["bathrooms"] = bathrooms
        container["toilets"] = toilets
        container["floors"] = floors
        container["pozo"] = pozo
        container["parking_spaces"] = parkingSpaces
        container["year_built"] = yearBuilt
        container["price"] = price
        container["price_exposure"] = priceExposure
        container["currency"] = currency.value
        container["expenses_price"] = expensesPrice
        container["expenses_currency"] = expensesCurrency.value
        container["apt_professional_use"] = professionalUse
        container["apt_commercial_use"] = commercialUse
        container["offers_financing"] = financing
        container["apt_credit"] = aptCredit
        container["in_private_community"] = inPrivateCommunity
        container["internal_id"] = internalId
        container["video"] = video
        container["reduced_mobility_compliant"] = reducedMovility
        container["display_address"] = displayAddress
        container["total_lot_size"] = dimensionLand
        container["total_area_built"] = dimensionTotalBuilt
        container["total_squared_meters_covered"] = dimensionCovered
        container["total_squared_meters_semicovered"] = dimensionSemicovered
        container["total_squared_meters_uncovered"] = dimensionUncovered
        container["quotes"] = quotes
        container["fee_quote"] = feeQuotes
        container["conditions"] = conditions.map { $0.value }.joined(separator: ",")
        container["type"] = type.value
        container["operation"] = operation.value
        container["listing_status"] = listingStatus.value
        container["features"] = features.map { $0.value }.joined(separator: ",")
        container["photos"] = photos.map { $0.value }.joined(separator: ",")
        container["opportunity"] = opportunity.value
    }
}
