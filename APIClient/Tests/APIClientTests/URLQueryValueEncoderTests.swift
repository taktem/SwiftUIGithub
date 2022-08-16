//
//  Created by taktem on 2022/08/14
//

import XCTest
@testable import APIClient

class URLQueryValueEncoderTests: XCTestCase {
    func testそれぞれのEncoderが正しく機能する() {
        Bool: do {
            XCTAssertEqual(
                URLQueryValueEncoderHandler.boolEncoder.encode(true),
                "true"
            )

            XCTAssertEqual(
                URLQueryValueEncoderHandler.boolEncoder.encode(false),
                "false"
            )
        }

        String: do {
            XCTAssertEqual(
                URLQueryValueEncoderHandler.stringEncoder.encode("てすと"),
                "てすと"
            )

            XCTAssertEqual(
                URLQueryValueEncoderHandler.stringEncoder.encode("!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"),
                "!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"
            )
        }

        Int: do {
            XCTAssertEqual(
                URLQueryValueEncoderHandler.intEncoder.encode(100),
                "100"
            )

            XCTAssertEqual(
                URLQueryValueEncoderHandler.int8Encoder.encode(Int8(100)),
                "100"
            )

            XCTAssertEqual(
                URLQueryValueEncoderHandler.int16Encoder.encode(Int16(100)),
                "100"
            )

            XCTAssertEqual(
                URLQueryValueEncoderHandler.int32Encoder.encode(Int32(100)),
                "100"
            )

            XCTAssertEqual(
                URLQueryValueEncoderHandler.int64Encoder.encode(Int64(100)),
                "100"
            )

            XCTAssertEqual(
                URLQueryValueEncoderHandler.uintEncoder.encode(UInt(100)),
                "100"
            )

            XCTAssertEqual(
                URLQueryValueEncoderHandler.uint8Encoder.encode(UInt8(100)),
                "100"
            )

            XCTAssertEqual(
                URLQueryValueEncoderHandler.uint16Encoder.encode(UInt16(100)),
                "100"
            )

            XCTAssertEqual(
                URLQueryValueEncoderHandler.uint32Encoder.encode(UInt32(100)),
                "100"
            )

            XCTAssertEqual(
                URLQueryValueEncoderHandler.uint64Encoder.encode(UInt64(100)),
                "100"
            )
        }
    }
}
