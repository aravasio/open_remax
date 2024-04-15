import GRDB

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
