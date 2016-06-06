//
//  SessionIdentifier.swift
//  Burrow
//
//  Created by Jaden Geller on 5/2/16.
//
//

import Logger

struct SessionIdentifier {
    private let backing: String
    
    init(_ string: String) {
        // TODO: Should we restrict this to alphanum?
        log.precondition(!string.characters.contains("-"), "Invalid character in session identifier.")
        self.backing = string
    }
}

extension String {
    init(_ sessionIdentifier: SessionIdentifier) {
        self = sessionIdentifier.backing
    }
}