//
//  Created by taktem on 2022/08/14
//

import Foundation

protocol URLQueryValueEncoderProtocol {
    static func shouldEncode(value: Any) -> Bool
    func encode(_ value: Any) -> String
}

struct URLQueryValueEncoder<T> {

    let encoder: ((T) -> String)

    func encode(_ value: T) -> String {
        return encoder(value)
    }
}

extension URLQueryValueEncoder: URLQueryValueEncoderProtocol {
    static func shouldEncode(value: Any) -> Bool {
        return type(of: value) == T.self
    }

    func encode(_ value: Any) -> String {
        return encode(value as! T)
    }
}

class URLQueryValueEncoderHandler {
    private let defaultEncoders: [URLQueryValueEncoderProtocol]

    private var customEncoders: [URLQueryValueEncoderProtocol] = []

    static let `default` = URLQueryValueEncoderHandler(defaultEncoders:
        [
            URLQueryValueEncoderHandler.boolEncoder,
            URLQueryValueEncoderHandler.stringEncoder,
            URLQueryValueEncoderHandler.doubleEncoder,
            URLQueryValueEncoderHandler.floatEncoder,
            URLQueryValueEncoderHandler.intEncoder,
            URLQueryValueEncoderHandler.int8Encoder,
            URLQueryValueEncoderHandler.int16Encoder,
            URLQueryValueEncoderHandler.int32Encoder,
            URLQueryValueEncoderHandler.int64Encoder,
            URLQueryValueEncoderHandler.uintEncoder,
            URLQueryValueEncoderHandler.uint8Encoder,
            URLQueryValueEncoderHandler.uint16Encoder,
            URLQueryValueEncoderHandler.uint32Encoder,
            URLQueryValueEncoderHandler.uint64Encoder
        ]
    )

    init(defaultEncoders: [URLQueryValueEncoderProtocol]) {
        self.defaultEncoders = defaultEncoders
    }

    func add(customEncoder: URLQueryValueEncoderProtocol) {
        customEncoders.insert(customEncoder, at: 0)
    }

    func encode(_ value: Any) throws -> String {
        for encoder in customEncoders {
            if type(of: encoder).shouldEncode(value: value) {
                return encoder.encode(value)
            }
        }

        for encoder in defaultEncoders {
            if type(of: encoder).shouldEncode(value: value) {
                return encoder.encode(value)
            }
        }

        throw RequestError.noEncoderAvailable(value: value)
    }
}

extension URLQueryValueEncoderHandler {
    static let boolEncoder = URLQueryValueEncoder<Bool>(encoder: {
        switch $0 {
        case true: return "true"
        case false: return "false"
        }
    })

    static let stringEncoder = URLQueryValueEncoder<String>(encoder: {
        return $0
    })

    static let doubleEncoder = URLQueryValueEncoder<Double>(encoder: {
        return String($0)
    })

    static let floatEncoder = URLQueryValueEncoder<Float>(encoder: {
        return String($0)
    })

    static let intEncoder = URLQueryValueEncoder<Int>(encoder: {
        return String($0)
    })

    static let int8Encoder = URLQueryValueEncoder<Int8>(encoder: {
        return String($0)
    })

    static let int16Encoder = URLQueryValueEncoder<Int16>(encoder: {
        return String($0)
    })

    static let int32Encoder = URLQueryValueEncoder<Int32>(encoder: {
        return String($0)
    })

    static let int64Encoder = URLQueryValueEncoder<Int64>(encoder: {
        return String($0)
    })

    static let uintEncoder = URLQueryValueEncoder<UInt>(encoder: {
        return String($0)
    })

    static let uint8Encoder = URLQueryValueEncoder<UInt8>(encoder: {
        return String($0)
    })

    static let uint16Encoder = URLQueryValueEncoder<UInt16>(encoder: {
        return String($0)
    })

    static let uint32Encoder = URLQueryValueEncoder<UInt32>(encoder: {
        return String($0)
    })

    static let uint64Encoder = URLQueryValueEncoder<UInt64>(encoder: {
        return String($0)
    })

    static let urlEncoder = URLQueryValueEncoder<URL>(encoder: {
        return $0.absoluteString
    })

    static let dateEncoder = URLQueryValueEncoder<Date>(encoder: {
        return String($0.timeIntervalSince1970)
    })
}
