//
//  GlanceViewModel.swift
//  AnyTime
//
//  Created by Tao Xu on 9/30/17.
//  Copyright © 2017 Tao Xu. All rights reserved.
//

import Foundation
import SwiftyUserDefaults
import EventKit

protocol GlanceViewModelOwner: class {
    var listView: UITableView { get }
    var visiable: Bool { get }
}

class GlanceViewModel: NSObject {
    var favs = [String]()
    var dateformat = ""
    var timezones = [TimeZoneItem]()
    var selectedDate: Date?
    let store = EKEventStore()

    weak var owner: GlanceViewModelOwner?
    var observers = [DefaultsDisposable]()

    override init() {
        super.init()
        finishInit()
    }

    convenience init(owner: GlanceViewModelOwner? = nil) {
        self.init()
        self.owner = owner
        finishInit()
    }

    func finishInit() {
        self.favs = Defaults.favorites
        self.dateformat = Defaults.format
        self.timezones = TimeZoneItem.get(ids: favs)

        observers.append(Defaults.observe(\.favorites, options: .new) { self.processFavorites(update: $0) })
        observers.append(Defaults.observe(\.format, options: .new) { self.processFormat(update: $0) })
        observers.append(Defaults.observe(\.preferCity, options: .new) { self.processPreferCity(update: $0) })
    }

    deinit {
        observers.forEach {  $0.dispose() }
        observers.removeAll()
    }

    func item(at indexPath: IndexPath) -> TimeZoneItem? {
        if indexPath.row < timezones.count {
            return timezones[indexPath.row]
        }
        return nil
    }

    func move(at indexPath: IndexPath, to: IndexPath) {
        timezones.move(at: indexPath.row, to: to.row)
        Defaults.favorites = timezones.map { $0.timezone.identifier }
    }

    func delete(at indexPath: IndexPath) {
        timezones.remove(at: indexPath.row)
        favs.remove(at: indexPath.row)
        Defaults.favorites = self.favs
    }

    private func processFavorites(update: DefaultsObserver<[String]>.Update) {
        if let new = update.newValue, new != self.favs {
            self.favs = new
            DispatchQueue.main.async {
                self.timezones = TimeZoneItem.get(ids: Defaults.favorites)
                self.owner?.listView.reloadData()
            }
        }
    }

    private func processFormat(update: DefaultsObserver<String>.Update) {
        if let new = update.newValue, new != self.dateformat {
            self.dateformat = new
            owner?.listView.reloadData()
        }
    }

    private func processPreferCity(update: DefaultsObserver<Int>.Update) {
        owner?.listView.reloadData()
    }
}
