//
//  GraphQLError.swift
//  GQLFetcher
//
//  Created by Evgeny Kalashnikov on 10/19/18.
//

import Foundation

public struct GraphQLError: CustomStringConvertible {
    
    public var description: String {
        var result = "message - \(self.message)\n"
        if let fields = self.fields { result += "fields - \(fields)\n" }
        if let locations = self.locations { result += "locations - \(locations)" }
        return result
    }
    
    
    public struct Location: CustomStringConvertible {
        public let line:   Int
        public let column: Int
        
        public init(data: GraphQLJSON) {
            self.line   = data["line"]   as! Int
            self.column = data["column"] as! Int
        }
        public var description: String {
            return "line - \(self.line), column - \(self.column)"
        }
    }
    
    public let message: String
    public let fields: [String]?
    public let locations: [Location]?
    
    init(data: GraphQLJSON) {
        self.message = (data["message"] as? String) ?? "Uknown error"
        self.fields  = data["fields"]  as? [String]
        
        if let locations = data["locations"] as? [GraphQLJSON] {
            self.locations = locations.map { Location(data: $0) }
            
        } else if data["line"] != nil && data["column"] != nil {
            self.locations = [
                Location(data: data),
            ]
        } else {
            self.locations = nil
        }
    }
}
