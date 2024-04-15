public struct ListingSlug: Codable {
    let value: String
    private enum CodingKeys: String, CodingKey {
        case value = "slug"
    }
}
