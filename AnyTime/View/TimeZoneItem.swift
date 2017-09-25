//
//  TimeZoneItem.swift
//  AnyTime
//
//  Created by Tao Xu on 9/25/17.
//  Copyright © 2017 Tao Xu. All rights reserved.
//

import Foundation

struct TimeZoneItem {
    let abbr: String
    let title: String
    let timezone: TimeZone
}

extension TimeZoneItem: Equatable, Hashable {
    public static func == (lhs: TimeZoneItem, rhs: TimeZoneItem) -> Bool {
        return lhs.timezone.hashValue == rhs.timezone.hashValue
    }

    public var hashValue: Int {
        return self.timezone.hashValue
    }
}
