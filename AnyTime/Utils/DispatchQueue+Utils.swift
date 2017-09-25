//
//  DispatchQueue+Utils.swift
//  AnyTime
//
//  Created by Tao Xu on 9/25/17.
//  Copyright © 2017 Tao Xu. All rights reserved.
//

import Foundation

extension DispatchQueue {
    func delay(ms delay: Int, execute: @escaping () -> Void) {
        self.asyncAfter(deadline: .now() + .milliseconds(delay), execute: execute)
    }
}
