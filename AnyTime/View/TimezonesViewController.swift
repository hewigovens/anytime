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

    lazy var viewModel: TimezonesViewModel = {
        let vm = TimezonesViewModel()
        vm.owner = self
        return vm
    }()
    weak var banner: NotificationBanner?

    lazy var searchView: UIView = {
        let search = UIView(backgroundColor: UIColor.white)
        search.fp_height = 50
        self.searchField.embedded(in: search)
        return search
    }()

    lazy var searchField: UITextField = {
        let textField = UITextField()
        let icon = FAKIonIcons.image(with: "ion-ios-search", size: 20)
        let image = UIImageView(image: icon)
        image.contentMode = .center
        image.fp_size = CGSize(width: 24, height: 24)
        textField.leftView = image
        textField.leftViewMode = .always
        textField.clearButtonMode = .always
        textField.placeholder = "Tap to search..."
        textField.returnKeyType = .search
        textField.textColor = UIColor.black25Percent()
        textField.addTarget(self, action: #selector(search(_:)), for: .editingDidEndOnExit)
        textField.delegate = self
        return textField
    }()

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
        viewModel.configure(ids: TimeZone.knownTimeZoneIdentifiers)
        configureNaviItems()
        configureSubviews()
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
        tableView.embedded(in: self.view)
        tableView.tableHeaderView = self.searchView
        tableView.setContentOffset(CGPoint(x: 0, y: 50), animated: false)
    }

    @objc func maximize() {
        self.maximizeToFullScreen()
    }

    @objc func search(_ textField: UITextField) {
        viewModel.search(keyword: textField.text?.trimmed ?? "")
    }

    @objc func close() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
}

extension TimezonesViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.data.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.data[section].items.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: TimeZoneCell = tableView.dequeueReusableCell(for: indexPath)
        guard let item = viewModel.timezone(with: indexPath) else { return cell }
        cell.highlight()
        cell.textLabel?.text = item.area.city
        cell.detailTextLabel?.text = item.timezone.offset(string: item.abbr)
        if viewModel.set.contains(item) {
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
        label.text = viewModel.data[section].prefix
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
        guard let item = viewModel.timezone(with: indexPath) else { return }
        if viewModel.add(item: item) {
            let banner = NotificationBanner(title: "\(item.area.city) added successfully.", style: .success)
            banner.duration = 1.5
            banner.show()
            self.banner = banner

            let cell = tableView.cellForRow(at: indexPath) as? TimeZoneCell
            cell?.infoLabel?.text = "\u{f443}"
            cell?.infoLabel?.sizeToFit()
            cell?.setNeedsDisplay()
        } else {
            let banner = NotificationBanner(title: "You have already added \(item.area.city).", style: .warning)
            banner.duration = 2
            banner.show()
            self.banner = banner
        }
    }
}

extension TimezonesViewController: TimezonesViewModelOwner {
    var listView: UITableView {
        return self.tableView
    }
}

extension TimezonesViewController: UITextFieldDelegate {
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        viewModel.search(keyword: "")
        return true
    }
}

extension TimezonesViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.searchField.resignFirstResponder()
    }
}
