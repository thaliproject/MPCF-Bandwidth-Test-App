//
//  Utils.swift
//  MPCFBandwidthTestApp
//
//  Created by Alex Telegin on 28/11/2016.
//  Copyright © 2016 Thali Project. All rights reserved.
//

import UIKit

internal extension Data {
    static func generateDataBy(numberOfBytes: Int) -> Data {
        let bytes = malloc(numberOfBytes)
        let data = Data(bytes: bytes!, count: numberOfBytes)
        free(bytes)
        return data
    }
}
