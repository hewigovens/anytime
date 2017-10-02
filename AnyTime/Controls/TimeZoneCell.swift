//
//  TimeZoneCell.swift
//  AnyTime
//
//  Created by Tao Xu on 9/24/17.
//  Copyright © 2017 Tao Xu. All rights reserved.
//

import Foundation
import Colours
import Reusable
import SwiftyUserDefaults

struct Area {
    let continent: String
    let country: String
    let city: String
}

extension TimeZoneItem {
    var area: Area {
        let array = self.title.split(separator: "/").map {$0.replacingOccurrences(of: "_", with: " ")}
        if array.count > 2 {
            return Area(continent: String(array[0]), country: String(array[1]), city: String(array[2]))
        } else if array.count == 2 {
            return Area(continent: String(array[0]), country: "", city: String(array[1]))
        }
        return Area(continent: String(array[0]), country: String(array[0]), city: String(array[0]))
    }
}

class TimeZoneCell: UITableViewCell, Reusable {
    static let reuseId = "TimeZoneCell"

    lazy var formatter: DateFormatter = {
        let dateformatter = DateFormatter()
        dateformatter.locale = Locale.current
        dateformatter.setLocalizedDateFormatFromTemplate(Defaults[.format])
        return dateformatter
    }()

    var timezone: TimeZoneItem? {
        didSet {
            guard let zone = self.timezone?.timezone else { return }
            self.formatter.timeZone = zone
            self.displayDate()
        }
    }

    var date: Date? {
        didSet {
            self.displayDate()
        }
    }

    var infoLabel: UILabel? {
        var label = self.accessoryView as? UILabel
        if label == nil {
            label = UILabel()
            label?.adjustsFontSizeToFitWidth = true
            label?.textAlignment = .right
            label?.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: UIFont.Weight.medium)
            self.textLabel?.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: UIFont.Weight.medium)
            self.accessoryView = label
        }
        return label
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func highlight() {
        let cell = self
        cell.backgroundColor = UIColor.white
        cell.backgroundView = nil
        cell.textLabel?.textColor = UIColor.black25Percent()
        cell.detailTextLabel?.textColor = UIColor.black25Percent()
        cell.infoLabel?.textColor = UIColor.black25Percent()
    }

    func unhighlight() {
        let cell = self
        cell.backgroundColor = UIColor.midnightBlue()
        cell.textLabel?.textColor = UIColor.ghostWhite()
        cell.detailTextLabel?.textColor = UIColor(red:0.51, green:0.53, blue:0.56, alpha:1.00)
        cell.infoLabel?.textColor = UIColor.ghostWhite()
    }

    func displayDate() {
        guard let timezone = self.timezone else { return }

        self.textLabel?.text = timezone.timezone.offset(string: timezone.abbr)
        self.detailTextLabel?.text = timezone.title.replacingOccurrences(of: "_", with: " ")
        self.textLabel?.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: .horizontal)
        self.infoLabel?.text = formatter.string(from: self.date ?? Date())
        self.infoLabel?.sizeToFit()
        let max = self.fp_width / 3 * 2
        if let width = self.infoLabel?.fp_width, width > max {
            self.infoLabel?.fp_width = max
        }
        self.setNeedsDisplay()
    }
}
