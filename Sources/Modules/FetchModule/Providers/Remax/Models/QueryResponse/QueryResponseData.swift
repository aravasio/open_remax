struct QueryResponseData: Codable {
    let slugs: [ListingSlug]
    let totalPages: Int
    let page: Int
    let totalItems: Int
    
    private enum CodingKeys: String, CodingKey {
        case slugs = "data"
        case totalPages, page, totalItems
    }
}
