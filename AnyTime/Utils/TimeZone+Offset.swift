//
//  TimeZone+Offset.swift
//  AnyTime
//
//  Created by Tao Xu on 9/25/17.
//  Copyright © 2017 Tao Xu. All rights reserved.
//

import Foundation

extension TimeZone {
    public var offset: Int {
        let offset = self.secondsFromGMT() / 3600
        return offset
    }

    public func offset(string: String) -> String {
        var text = string
        if offset != 0 {
            text = "\(string) \(offset > 0 ? "+": "")\(offset)"
        }
        return text
    }
}
