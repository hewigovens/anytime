//
//  SettingsViewController.swift
//  AnyTime
//
//  Created by Tao Xu on 9/25/17.
//  Copyright © 2017 Tao Xu. All rights reserved.
//

import UIKit
import FontAwesomeKit
import SwiftyUserDefaults
import StoreKit

let reuseId = "SettingsCell"

struct SettingSection {
    let title: String
    let items: [SettingItem]
}

struct SettingItem {
    let title: String
    let value: String
    var icon: UIImage?
    var action: (() -> Void)?
}

extension FAKIcon {
    class func image(with identifier: String, size: Int = 22) -> UIImage? {
        let icon = try? self.init(identifier: identifier, size: CGFloat(size))
        return icon?.image(with: CGSize(width: size, height: size))
    }
}

class SettingsViewController: UITableViewController {

    var sections = [SettingSection]()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureData()
        configureNaviItems()
        configureSubviews()
    }
    func configureData() {

        sections.append(SettingSection(title: "Format", items: [
            SettingItem(title: "Format", value: Defaults[.format], icon: FAKIonIcons.image(with: "ion-ios-clock-outline"), action: {
                //
            })
        ]))

        sections.append(SettingSection(title: "Donate", items: [
            SettingItem(title: "Donate bitcoin", value: "", icon: FAKIonIcons.image(with: "ion-social-bitcoin-outline"), action: {

            })
        ]))

        sections.append(SettingSection(title: "About", items: [
            SettingItem(title: "Rate Us", value: "", icon: FAKIonIcons.image(with: "ion-ios-heart-outline"), action: {
                SKStoreReviewController.requestReview()
            }),
            SettingItem(title: "Feedback", value: "", icon: FAKIonIcons.image(with: "ion-ios-email-outline"), action: {
                //
            }),
            SettingItem(title: "About", value: "", icon: FAKIonIcons.image(with: "ion-ios-information-outline"), action: {
                //
            })
        ]))
    }

    func configureNaviItems() {
        self.title = "Settings"
        let size: CGFloat = 30
        let icon = FAKIonIcons.iosCloseEmptyIcon(withSize: size)
        let image = icon?.image(with: CGSize(width: size, height: size))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(close))
    }
    func configureSubviews() {
        self.tableView.backgroundColor = UIColor.iceberg()
//        self.tableView.backgroundColor = .clear
//        self.tableView.backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseId)
        self.tableView.tableFooterView = self.createFooterView()
    }

    @objc func close() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
}

extension SettingsViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 24
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView(backgroundColor: UIColor.iceberg())
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseId, for: indexPath)
        let item = sections[indexPath.section].items[indexPath.row]
        cell.textLabel?.text = item.title
        cell.textLabel?.font = UIFont.systemFont(ofSize: 15)
        cell.textLabel?.textColor = UIColor.black25Percent()
        cell.imageView?.image = item.icon
        if item.value.lengthOfBytes(using: .utf8) > 0 {
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
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sections[indexPath.section].items[indexPath.row]
        item.action?()
    }

    func createFooterView() -> UIView {
        let view = UIView(backgroundColor: UIColor.clear)

        let height = sections.reduce(0) { (height, section) -> Int in
            return height + 24 + section.items.count * 44
        }
        view.fp_height = self.view.fp_height - CGFloat(height) - 64

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Dev"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "9999"

        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        label.numberOfLines = 0
        label.textColor = UIColor.black25Percent()
        label.textAlignment = .center
        label.text = """
        AnyTime: \(version)(\(build))
        built with ♥ by Fourplex Labs
        """
        label.embedded(in: view) { make in
            make.leading.equalToSuperview().offset(50)
            make.trailing.equalToSuperview().offset(-50)
            make.bottom.equalToSuperview().offset(50)
        }
        return view
    }
}
