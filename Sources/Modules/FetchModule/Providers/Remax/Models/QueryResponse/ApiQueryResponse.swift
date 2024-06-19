struct ApiQueryResponse: Codable {
    let page: QueryResponseData
    let code: Int?
    let message: String?
    let errors: [String]?
    
    private enum CodingKeys: String, CodingKey {
        case page = "data"
        case code, message, errors
    }
}
