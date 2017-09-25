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

extension TimeZoneItem {
    var area: (continent: String, city: String) {
        let array = self.title.split(separator: "/")
        if array.count < 2 {
            return (String(array[0]), String(array[0]))
        }
        return (String(array[0]), String(array[1]).replacingOccurrences(of: "_", with: " "))
    }
}

class TimeZoneCell: UITableViewCell, Reusable {
    static let reuseId = "TimeZoneCell"

    lazy var formatter: DateFormatter = {
        let dateformatter = DateFormatter()
        dateformatter.locale = Locale.current
        dateformatter.setLocalizedDateFormatFromTemplate("HH:mm MMM d yyyy")
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
            label?.textAlignment = .right
            label?.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: UIFont.Weight.medium)
            self.textLabel?.font = label?.font
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
        cell.detailTextLabel?.textColor = UIColor.ghostWhite()
        cell.infoLabel?.textColor = UIColor.ghostWhite()
    }

    func displayDate() {
        guard let timezone = self.timezone else { return }

        self.textLabel?.text = timezone.timezone.offset(string: timezone.abbr)
        self.detailTextLabel?.text = timezone.title
        self.infoLabel?.text = formatter.string(from: self.date ?? Date())
        self.infoLabel?.sizeToFit()
        self.setNeedsDisplay()
    }
}
