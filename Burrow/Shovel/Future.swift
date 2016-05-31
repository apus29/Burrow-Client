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
    public init(@noescape resolution: Callback throws -> ()) rethrows {
        self.init()
        
        // Setup the resolution for the callback
        try resolution { value in
            self.resolver.resolve(with: value)
        }
    }
    
    public init(value: Element) {
        self.init()
        self.resolver.resolve(with: value)
    }
    
    public func then(block: Element -> ()) {
        self.resolver.register { value in block(value) }
    }
    
    public func map<V>(transform: Element -> V) -> Future<V> {
        return Future<V> { resolve in
            then { resolve(transform($0)) }
        }
    }
    
    public func flatMap<V>(transform: Element -> Future<V>) -> Future<V> {
        return Future<V> { resolve in
            then { transform($0).then { resolve($0) } }
        }
    }
}

extension Future where Element: ResultType {
    public func onSuccess(block: Element.Element -> ()) {
        then { result in
            if let successValue = try? result.unwrap() {
                block(successValue)
            }
        }
    }
    
    public func onFailure(block: ErrorType -> ()) {
        then { result in
            do {
                try result.unwrap()
            } catch let error {
                block(error)
            }
        }
    }
    
    public func mapSuccess<V>(transform: Element.Element throws -> V) -> Future<Result<V>> {
        return Future<Result<V>> { resolve in
            then { value in resolve(Result { try transform(value.unwrap()) }) }
        }
    }
    
    func flatMapSuccess<V>(transform: Element.Element throws -> Future<Result<V>>) -> Future<Result<V>> {
        return Future<Result<V>> { resolve in
            then { value in
                do {
                    try transform(value.unwrap()).then(resolve)
                } catch let error {
                    resolve(.Failure(error))
                }
            }
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

