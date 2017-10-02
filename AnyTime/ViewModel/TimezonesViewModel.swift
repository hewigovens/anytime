//
//  TimezonesViewModel.swift
//  AnyTime
//
//  Created by Tao Xu on 10/2/17.
//  Copyright © 2017 Tao Xu. All rights reserved.
//

import Foundation
import SwiftyUserDefaults

protocol TimezonesViewModelOwner: class {
    var listView: UITableView { get }
}

class TimezonesViewModel {
    var data = [(prefix: String, items: [TimeZoneItem])]()
    var all = [(prefix: String, items: [TimeZoneItem])]()
    var ids = TimeZone.knownTimeZoneIdentifiers
    var set = Set<TimeZoneItem>()
    var searching = false
    weak var owner: TimezonesViewModelOwner?

    func configure(ids: [String]) {
        let items = TimeZoneItem.get(ids: ids)
        let fav = TimeZoneItem.get(ids: Defaults[.favorites])
        let predicate = { (item: TimeZoneItem) -> String in
            if item.title == "UTC" || item.title == "GMT" {
                return "N/A"
            }
            let area = item.area
            var header = area.continent
            if area.country.length > 0 {
                header.append("/\(area.country)")
            }
            return header
        }
        set = Set<TimeZoneItem>(fav)
        data = Dictionary.init(grouping: items, by: predicate).map { return ($0.key, $0.value) }
        if all.count == 0 { all = data }
    }

    func search(keyword: String) {
        if keyword.length <= 0 {
            self.data = self.all
            owner?.listView.reloadData()
            return
        }
        if self.searching {
            return
        }
        self.searching = true
        let matches = self.ids.filter {$0.contains(keyword)}
        self.configure(ids: matches)
        owner?.listView.reloadData()
        self.searching = false
    }

    func add(item: TimeZoneItem) -> Bool {
        if self.set.contains(item) {
            return false
        } else {
            var favs = Defaults[.favorites]
            favs.append(item.timezone.identifier)
            Defaults.set(.favorites, favs)
            Defaults.synchronize()
            set.insert(item)
            return true
        }
    }

    func timezone(with indexPath: IndexPath) -> TimeZoneItem? {
        guard indexPath.section < data.count else {
            return nil
        }
        guard indexPath.row < data[indexPath.section].items.count else {
            return nil
        }
        return data[indexPath.section].items[indexPath.row]
    }
}
