//
//  UITableViewCell+SettingItem.swift
//  AnyTime
//
//  Created by Tao Xu on 10/2/17.
//  Copyright © 2017 Tao Xu. All rights reserved.
//

import UIKit

extension UITableViewCell {

    static let settingsCellId = "SettingsCell"

    func configure(item: SettingItem) {
        let cell = self
        cell.textLabel?.text = item.title
        cell.textLabel?.font = UIFont.systemFont(ofSize: 15)
        cell.textLabel?.textColor = UIColor.black25Percent()
        cell.imageView?.image = item.icon
        if item.value.length > 0 {
            var label = cell.accessoryView as? UILabel
            if label == nil {
                label = UILabel()
                label?.font = UIFont.systemFont(ofSize: 15)
                label?.textColor = UIColor.black25Percent()
                cell.accessoryView = label
            }
            label?.text = item.value
            label?.sizeToFit()
        }
    }
}
