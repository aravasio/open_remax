class Debug {
    static let shared: Debug = Debug()
    
    // change this value
    private let IS_DEBUG: Bool = true

    private init() {}

    func log(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        if IS_DEBUG {
            print(items)
        }
    }
}