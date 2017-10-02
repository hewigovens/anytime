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
        return timezone.hashValue
    }
}

func combineHashes(_ hashes: [Int]) -> Int {
    return hashes.reduce(0, combineHashValues)
}

func combineHashValues(_ initial: Int, _ other: Int) -> Int {
    #if arch(x86_64) || arch(arm64)
        let magic: UInt = 0x9e3779b97f4a7c15
    #elseif arch(i386) || arch(arm)
        let magic: UInt = 0x9e3779b9
    #endif
    var lhs = UInt(bitPattern: initial)
    let rhs = UInt(bitPattern: other)
    lhs ^= rhs &+ magic &+ (lhs << 6) &+ (lhs >> 2)
    return Int(bitPattern: lhs)
}
