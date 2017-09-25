//
//  ViewController.swift
//  AnyTime
//
//  Created by Tao Xu on 9/23/17.
//  Copyright © 2017 Tao Xu. All rights reserved.
//

import UIKit
import Reusable
import Colours
import SwiftyUserDefaults
import SnapKit
import FontAwesomeKit

class GlanceViewController: UITableViewController {

    var favs = [String]()
    var timezones = [TimeZoneItem]()
    var selectedDate: Date?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.favs = Defaults[.favorites]
        self.configureNaviItem()
        self.configureData()
        self.configureSubviews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let favs = Defaults[.favorites]
        if self.favs != favs {
            self.favs = favs
            self.timezones = Defaults.favorites()
            self.tableView.reloadData()
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.timezones.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: TimeZoneCell = tableView.dequeueReusableCell(for: indexPath)
        if indexPath.row > self.timezones.count {
            return cell
        }
        let timezone = self.timezones[indexPath.row]
        cell.date = self.selectedDate
        cell.timezone = timezone
        print("cellForRowAt \(indexPath) \(timezone.title)")
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let height: CGFloat = 64
        if indexPath.row == 0 {
            return 100
        }
        return height
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)
        let topIndex = IndexPath(row: 0, section: 0)
        let secondIndex = IndexPath(row: 1, section: 0)
        if indexPath == topIndex {
            self.showDatePicker()
            return
        }
        tableView.beginUpdates()
        self.timezones.move(at: indexPath.row, to: topIndex.row)
        tableView.moveRow(at: indexPath, to: topIndex)
        tableView.endUpdates()

        if indexPath.row > tableView.visibleCells.count - 1 {
            tableView.reloadData()
            tableView.setContentOffset(CGPoint(x: 0, y: -tableView.contentInset.top), animated: true)
        } else {
            DispatchQueue.main.delay(ms: 500) {
                tableView.reloadRows(at: [topIndex, secondIndex], with: .automatic)
                tableView.setContentOffset(CGPoint(x: 0, y: -tableView.contentInset.top), animated: true)
            }
        }
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? TimeZoneCell else { return }
        if indexPath.row == 0 {
            cell.highlight()
        } else {
            cell.unhighlight()
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.row == 0 {
            return false
        }
        if self.timezones.count < 2 {
            return false
        }
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            self.timezones.remove(at: indexPath.row)
            self.favs.remove(at: indexPath.row)
            Defaults.set(.favorites, self.favs)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
        }
    }
}

extension GlanceViewController {
    @objc func addTimezone() {
        let vc = TimezonesViewController()
        self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }

    @objc func showSettings() {
        let vc = SettingsViewController(style: .grouped)
        self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }

    func showDatePicker() {
        let picker = DateTimePicker.show(selected: Date())
        picker.todayButtonTitle = "Now"
        picker.doneButtonTitle = "Done"
        picker.timeZone = self.timezones[0].timezone

        let dateformatter = DateFormatter()
        dateformatter.locale = Locale.current
        dateformatter.setLocalizedDateFormatFromTemplate("HH:mm MMM d yyyy")
        picker.dateFormat = dateformatter.dateFormat
        picker.completionHandler = { [weak self] date in
            guard let ss = self else { return }
            ss.selectedDate = date
            for i in 0..<ss.timezones.count {
                let idx = IndexPath(row: i, section: 0)
                guard let cell = ss.tableView.cellForRow(at: idx) as? TimeZoneCell else {
                    continue
                }
                cell.date = date
            }
        }
    }

    func configureNaviItem() {
        self.title = "AnyTime"
        let rightSize: CGFloat = 30
        let rightIcon = FAKIonIcons.iosPlusEmptyIcon(withSize: rightSize)
        rightIcon?.addAttribute(NSAttributedStringKey.foregroundColor.rawValue, value: UIColor.black)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: rightIcon?.image(with: CGSize(width: rightSize, height: rightSize)), style: .plain, target: self, action: #selector(addTimezone))

        let leftSize: CGFloat = 24
        let leftIcon = FAKIonIcons.iosGearOutlineIcon(withSize: leftSize)
        rightIcon?.addAttribute(NSAttributedStringKey.foregroundColor.rawValue, value: UIColor.black)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: leftIcon?.image(with: CGSize(width: leftSize, height: leftSize)), style: .plain, target: self, action: #selector(showSettings))
    }

    func configureData() {
        self.timezones = Defaults.favorites()
    }

    func configureSubviews() {
        self.tableView.register(cellType: TimeZoneCell.self)
        self.tableView.separatorStyle = .none
        self.tableView.backgroundColor = UIColor.midnightBlue()
        self.tableView.tableFooterView = UIView()
        self.configureHeader()
    }

    func configureHeader() {
        let height: CGFloat = 550
        self.tableView.tableHeaderView = self.createHeader(height: height)
        self.tableView.contentInset = UIEdgeInsets(top: -height, left: 0, bottom: 0, right: 0)
    }

    func createHeader(height: CGFloat) -> UIView {
        let header = UIView()
        let label = UILabel()
        label.text = "You're wasting time here."
        label.textColor = UIColor.black25Percent()
        label.sizeToFit()
        header.addSubview(label)
        header.backgroundColor = UIColor.white
        header.fp_height = height
        label.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-150)
            make.centerX.equalToSuperview()
        }
        let label2 = UILabel()
        label2.text = "Fine, you win."
        label2.textColor = label.textColor
        label2.sizeToFit()
        header.addSubview(label2)
        label2.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(80)
        }
        return header
    }
}
