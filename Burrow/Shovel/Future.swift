//
//  Future.swift
//  Burrow
//
//  Created by Jaden Geller on 5/29/16.
//
//


public struct Future<Element> {
    public typealias Callback = Element -> ()
    private let resolver = Resolver<Element>()
}

extension Future {
    init(@noescape resolution: Callback -> ()) {
        self.init()
        
        // Setup the resolution for the callback
        resolution { value in
            self.resolver.resolve(with: value)
        }
    }
    
    func then(block: Element -> ()) {
        self.resolver.register { value in block(value) }
    }
    
    func map<V>(transform: Element -> V) -> Future<V> {
        return Future<V> { resolve in
            then { resolve(transform($0)) }
        }
    }
    
    func flatMap<V>(transform: Element -> Future<V>) -> Future<V> {
        return Future<V> { resolve in
            then { transform($0).then { resolve($0) } }
        }
    }
}

extension Future {
    static func awaiting(allOf futures: [Future]) -> Future<[Element]> {
        return Future<[Element]> { resolve in
            var unfinished = Set(futures.indices)
            var results: [Element?] = Array(Repeat(count: futures.count, repeatedValue: nil))
            for (index, future) in futures.enumerate() {
                future.then { value in
                    // Record the result
                    unfinished.remove(index)
                    results[index] = value
                    
                    // If all other futures all finished, resolve!
                    if unfinished.isEmpty { resolve(results.map { $0! }) }
                }
            }
        }
    }
}
