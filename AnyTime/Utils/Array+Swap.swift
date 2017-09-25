//
//  Array+Swap.swift
//  AnyTime
//
//  Created by Tao Xu on 9/24/17.
//  Copyright © 2017 Tao Xu. All rights reserved.
//

import Foundation

extension Array {
    //swiftlint:disable identifier_name
    public mutating func move(at: Index, to: Index) {
        let item = self.remove(at: at)
        self.insert(item, at: to)
    }
    //swiftlint:enable identifier_name
}
