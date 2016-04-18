//
//  Domain.swift
//  Burrow
//
//  Created by Jaden Geller on 4/17/16.
//
//

public struct Domain {
    public var labels: [String]
    
    public init(labels: [String]) {
        self.labels = labels
    }
}

extension Domain: StringLiteralConvertible {
    public init(_ string: String) {
        self.labels = string.componentsSeparatedByString(".")
        precondition(domainTextualLength < Domain.maxDomainTextualLength)
        labels.forEach{ precondition($0.utf8.count < Domain.maxLabelLength) }
    }
    
    public init(stringLiteral value: String) {
        self.init(value)
    }
    
    public init(unicodeScalarLiteral value: String) {
        self.init(value)
    }
    
    public init(extendedGraphemeClusterLiteral value: String) {
        self.init(value)
    }
}

extension String {
    public init(_ domain: Domain) {
        self = domain.labels.joinWithSeparator(".")
    }
}

extension Domain {
    private static let maxLabelLength = 63
    private static let maxDomainTextualLength = 253
    
    public var domainTextualLength: Int {
        return (labels.count - 1) + labels.lazy.map{ $0.utf8.count }.reduce(0, combine: +)
    }
    
    private var maxNextLabelLength: Int {
        return min(
            Domain.maxLabelLength,
            Domain.maxDomainTextualLength - domainTextualLength - 1
        )
    }
}

extension Domain {
    public mutating func prepend(label: String) {
        precondition(!label.containsString("."))
        precondition(label.utf8.count <= Domain.maxLabelLength)
        labels.insert(label, atIndex: 0)
        precondition(domainTextualLength <= Domain.maxDomainTextualLength)
    }
    
    public func prepending(label: String) -> Domain {
        var copy = self
        copy.prepend(label)
        return copy
    }
}

extension Domain {
    static func package(data: NSData, underDomain domain: (index: Int) -> Domain) -> [Domain] {
        let data = data.base64EncodedStringWithOptions([]).utf8
        var dataIndex = data.startIndex
        
        // In each iteration of the loop, build a single domain and add it to the array.
        var domains: [Domain] = []
        var countIndex = 0
        while dataIndex != data.endIndex {
            defer { countIndex += 1 }
            
            // Get the correct parent domain.
            var domain = domain(index: countIndex)
            
            // In each iteration, append a data label to the domain
            // looping while there is still data to append and space to append it
            while true {
                let nextLabelLength = min(
                    domain.maxNextLabelLength,
                    dataIndex.distanceTo(data.endIndex)
                )
                guard nextLabelLength > 0 else { break }
                
                // From the length, compute the end index
                let labelEndIndex = dataIndex.advancedBy(nextLabelLength)
                defer { dataIndex = labelEndIndex }
                
                // Prepend the component
                domain.prepend(String(data[dataIndex..<labelEndIndex]))
            }
            
            domains.append(domain)
        }
        
        return domains
    }
}

