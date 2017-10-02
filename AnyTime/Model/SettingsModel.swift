//
//  SettingsModel.swift
//  AnyTime
//
//  Created by Tao Xu on 10/2/17.
//  Copyright © 2017 Tao Xu. All rights reserved.
//

import UIKit

struct SettingSection {
    let title: String
    var items: [SettingItem]
}

struct SettingItem {
    let title: String
    var value: String
    var icon: UIImage?
    var action: (() -> Void)?
}
