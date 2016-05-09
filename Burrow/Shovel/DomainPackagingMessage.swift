//
//  DomainPackagingMessage.swift
//  Burrow
//
//  Created by Jaden Geller on 5/9/16.
//
//

internal struct DomainPackagingMessage {
    typealias DomainFormat = (sequenceNumber: Int) -> Domain
    
    private let dataString: String.UTF8View
    private let domainFormat: DomainFormat
    
    // Will not encode data.
    init(domainSafeString string: String, underDomain domainFormat: DomainFormat) {
        precondition(string.rangeOfCharacterFromSet(domainSafeCharacterSet.invertedSet) == nil,
                     "String to package is not domain safe.")
        precondition(string.characters.first != "-" && string.characters.last != "-",
                     "String may not start or end with dash.")
        precondition(string.characters.count > 0, "String must have length greater than zero.")

        self.dataString = string.utf8
        self.domainFormat = domainFormat
    }
    
    // Will encode data making it 25% longer.
    init(arbitraryData data: NSData, underDomain domainFormat: DomainFormat) {
        precondition(data.length > 0, "Data must have length greater than zero.")

        self.dataString = data.base64EncodedStringWithOptions([]).utf8
        self.domainFormat = domainFormat
    }
}

extension DomainPackagingMessage: SequenceType {
    func generate() -> AnyGenerator<Domain> {
        var dataIndex = dataString.startIndex
        var sequenceNumber = 0
        
        // Return a generator that will return the data-packed domains sequentially.
        return AnyGenerator {
            // Once we package all the data, do not return any more domains.
            guard dataIndex != self.dataString.endIndex else { return nil }
            
            // Increment sequence number with each iteration
            defer { sequenceNumber += 1 }
            
            // Get the correct parent domain.
            var domain = self.domainFormat(sequenceNumber: sequenceNumber)
            
            // Record the number of levels in the domain so we can prepend before them.
            let level = domain.level
            
            // In each iteration, append a data label to the domain
            // looping while there is still data to append and space to append it
            while true {
                let nextLabelLength = min(
                    domain.maxNextLabelLength,
                    dataIndex.distanceTo(self.dataString.endIndex)
                )
                guard nextLabelLength > 0 else { break }
                
                // From the length, compute the end index
                let labelEndIndex = dataIndex.advancedBy(nextLabelLength)
                defer { dataIndex = labelEndIndex }
                
                // Prepend the component
                domain.prepend(String(self.dataString[dataIndex..<labelEndIndex]), atLevel: level)
            }

            return domain
        }

    }
}

// MARK: Helpers

// TODO: Does this accurately represent this character set?
private let domainSafeCharacterSet: NSCharacterSet = {
    let set = NSMutableCharacterSet()
    set.formUnionWithCharacterSet(NSCharacterSet.alphanumericCharacterSet())
    set.addCharactersInString("-")
    set.addCharactersInString("=")
    return set
    
}()
