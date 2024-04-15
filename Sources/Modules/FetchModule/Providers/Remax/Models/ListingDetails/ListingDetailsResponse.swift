import GRDB

struct ListingDetailsResponse: Codable {
    let data: ListingDetail
    let code: Int
    let message: String
    let errors: [String]?
}
