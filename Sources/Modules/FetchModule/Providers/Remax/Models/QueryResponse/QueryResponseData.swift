struct QueryResponseData: Codable {
    let slugs: [ListingSlug]
    
    private enum CodingKeys: String, CodingKey {
        case slugs = "data"
    }
}
