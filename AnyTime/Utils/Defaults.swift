//
//  Defaults.swift
//  AnyTime
//
//  Created by Tao Xu on 9/24/17.
//  Copyright © 2017 Tao Xu. All rights reserved.
//

import Foundation
import SwiftyUserDefaults

public func registerDefaults() {
    UserDefaults.standard.register(defaults:[
        "favorites": [
        "UTC",
        "GMT",
        "HKT",
        "JST",
        "CST",
        "PDT"],
        "format": "HH:mm MMM d yyyy"
    ])
}

enum AnyTimeKey: String {
    case favorites
    case format
}

extension DefaultsKeys {
    static let favorites = DefaultsKey<[String]>(AnyTimeKey.favorites.rawValue)
    static let format = DefaultsKey<String>(AnyTimeKey.format.rawValue)
}

extension UserDefaults {

    func getFavorites() -> [TimeZoneItem] {
        let abbrDict = TimeZone.abbreviationDictionary
        return self[.favorites].map { key -> TimeZoneItem in
            let value = abbrDict[key]
            return TimeZoneItem(abbr: key, title: value!, timezone: TimeZone(abbreviation: key)!)
        }
    }
}
