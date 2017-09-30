//
//  TimezonesViewController.swift
//  AnyTime
//
//  Created by Tao Xu on 9/25/17.
//  Copyright © 2017 Tao Xu. All rights reserved.
//

import UIKit
import SnapKit
import FontAwesomeKit
import Reusable
import SwiftyUserDefaults
import NotificationBannerSwift

let timezonesCellId = "TimezonesCell"

class TimezonesViewController: UIViewController, HalfModalPresentable {

    var data = [(prefix: String, items: [TimeZoneItem])]()
    var set = Set<TimeZoneItem>(Defaults.getFavorites())
    weak var banner: NotificationBanner?

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView.backgroundColor = UIColor.iceberg()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(cellType: TimeZoneCell.self)
        tableView.tableFooterView = UIView()
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureData()
        configureNaviItems()
        configureSubviews()
    }

    func configureData() {
        let items = TimeZone.abbreviationDictionary.map { TimeZoneItem(abbr: $0.key, title: $0.value, timezone: TimeZone(abbreviation: $0.key)!)
        }
        let predicate = { (item: TimeZoneItem) -> String in
            if item.title == "UTC" || item.title == "GMT" {
                return "N/A"
            }
            let array = item.title.split(separator: "/")
            if array.count > 0 {
                return String(array[0])
            }
            return item.title
        }
        self.data = Dictionary.init(grouping: items, by: predicate).map { return ($0.key, $0.value) }
    }

    func configureNaviItems() {
        self.title = "Timezones"
        let image = FAKIonIcons.image(with: "ion-ios-close-empty", size: 30)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(close))
        let up_image = FAKIonIcons.image(with: "ion-ios-arrow-up", size: 24)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: up_image, style: .plain, target: self, action: #selector(maximize))
    }

    func configureSubviews() {
        self.view.backgroundColor = .clear
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalToSuperview().offset(0)
        }
    }

    @objc func maximize() {
        self.maximizeToFullScreen()
    }

    func add(item: TimeZoneItem) -> Bool {
        if self.set.contains(item) {
            let banner = NotificationBanner(title: "You have already added \(item.area.city).", style: .warning)
            banner.duration = 2
            banner.show()
            self.banner = banner
            return false
        } else {
            var favs = Defaults[.favorites]
            favs.append(item.abbr)
            Defaults.set(.favorites, favs)
            Defaults.synchronize()
            set.insert(item)
            let banner = NotificationBanner(title: "\(item.area.city) added successfully.", style: .success)
            banner.duration = 1.5
            banner.show()
            self.banner = banner
            return true
        }
    }

    @objc func close() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
}

extension TimezonesViewController: UITableViewDelegate, UITableViewDataSource {

    func timezone(with indexPath: IndexPath) -> TimeZoneItem? {
        guard indexPath.section < self.data.count else {
            return nil
        }
        guard indexPath.row < self.data[indexPath.section].items.count else {
            return nil
        }
        return self.data[indexPath.section].items[indexPath.row]
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.data.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.data[section].items.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: TimeZoneCell = tableView.dequeueReusableCell(for: indexPath)
        guard let item = self.timezone(with: indexPath) else { return cell }
        cell.highlight()
        cell.textLabel?.text = item.area.city
        cell.detailTextLabel?.text = item.timezone.offset(string: item.abbr)
        if set.contains(item) {
            cell.infoLabel?.text = "\u{f443}"
        } else {
            cell.infoLabel?.text = "\u{f442}"
        }
        cell.infoLabel?.font = FAKIonIcons.iconFont(withSize: 18)
        cell.infoLabel?.sizeToFit()
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? TimeZoneCell else { return }
        cell.highlight()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = UIColor.iceberg()
        let label = UILabel()
        label.text = self.data[section].prefix
        label.textColor = UIColor.black25Percent()
        label.sizeToFit()
        header.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
        }
        return header
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.banner?.dismiss()
        guard let item = self.timezone(with: indexPath) else { return }
        if self.add(item: item) {
            let cell = tableView.cellForRow(at: indexPath) as? TimeZoneCell
            cell?.infoLabel?.text = "\u{f443}"
            cell?.infoLabel?.sizeToFit()
            cell?.setNeedsDisplay()
        }
    }
}
