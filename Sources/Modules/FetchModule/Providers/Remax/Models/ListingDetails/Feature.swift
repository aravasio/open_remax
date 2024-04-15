import GRDB

struct Feature: Codable {
    let id: Int
    let value: String
    let lang: String
    let category: String
}
