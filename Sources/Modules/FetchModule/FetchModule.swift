//
//  File.swift
//
//
//  Created by Alejandro Ravasio on 17/03/2024.
//

import Foundation

public class FetchModule {
    
    public init() {}
    
    public func fetch() async throws -> [ListingDetail] {
        let provider = RemaxProvider()
        return try await provider.fetch(retryCount: 0)
    }
}
