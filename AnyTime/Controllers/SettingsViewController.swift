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
    var items: [SettingItem]
}

struct SettingItem {
    let title: String
    var value: String
    var icon: UIImage?
    var action: (() -> Void)?
}

class SettingsViewController: UITableViewController, HalfModalPresentable {

    var sections = [SettingSection]()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureData()
        configureNaviItems()
        configureSubviews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateFormatIfNeeded()
    }

    func updateFormatIfNeeded() {
        if sections[0].items[0].value != Defaults[.format] {
            sections[0].items[0].value = Defaults[.format]
            tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        }
    }

    func configureData() {

        sections.append(SettingSection(title: "Format", items: [
            SettingItem(title: "Format", value: Defaults[.format], icon: FAKIonIcons.image(with: "ion-ios-clock-outline"), action: { [weak self] in
                let editor = FormatEditorViewController()
                self?.navigationController?.pushViewController(editor, animated: true)
            })
        ]))

        sections.append(SettingSection(title: "Donate", items: [
            SettingItem(title: "Donate", value: "", icon: FAKIonIcons.image(with: "ion-social-bitcoin-outline"), action: { [weak self] in
                let vc = DonationViewController()
                self?.navigationController?.pushViewController(vc, animated: true)
            })
        ]))

        sections.append(SettingSection(title: "About", items: [
            SettingItem(title: "Rate Us", value: "", icon: FAKIonIcons.image(with: "ion-ios-heart-outline"), action: {
                SKStoreReviewController.requestReview()
            }),
            SettingItem(title: "Feedback", value: "", icon: FAKIonIcons.image(with: "ion-ios-email-outline"), action: { [weak self] in
                if let result = self?.canSendMail, result == true {
                    self?.feedbackWithEmail()
                } else {
                    self?.feedbackWithMailTo()
                }
            }),
            SettingItem(title: "About", value: "", icon: FAKIonIcons.image(with: "ion-ios-information-outline"), action: { [weak self] in
                self?.maximize()
                self?.tableView.setContentOffset(CGPoint(x: 0, y: 64), animated: true)
            })
        ]))
    }

    func configureNaviItems() {
        self.title = "Settings"
        let image = FAKIonIcons.image(with: "ion-ios-close-empty", size: 30)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(close))
        let up_image = FAKIonIcons.image(with: "ion-ios-arrow-up", size: 24)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: up_image, style: .plain, target: self, action: #selector(maximize))
    }
    func configureSubviews() {
        self.tableView.backgroundColor = UIColor.iceberg()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseId)
        self.tableView.tableFooterView = self.createFooterView()
    }

    @objc func close() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }

    @objc func maximize() {
        self.maximizeToFullScreen()
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
