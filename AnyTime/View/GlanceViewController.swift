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
import EventKitUI

class GlanceViewController: UITableViewController {

    let feedback = UIImpactFeedbackGenerator(style: .light)
    var viewModel: GlanceViewModel!
    weak var picker: DatePicker?

    //swiftlint:disable weak_delegate
    var halfModalTransitioningDelegate: HalfModalTransitioningDelegate?
    //swiftlint:enable weak_delegate

    override func viewDidLoad() {
        super.viewDidLoad()

        self.viewModel = GlanceViewModel(owner: self)
        self.configureNaviItem()
        self.configureSubviews()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.timezones.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: TimeZoneCell = tableView.dequeueReusableCell(for: indexPath)
        guard let timezone = self.viewModel.item(at: indexPath) else { return cell }
        cell.formatter.setLocalizedDateFormatFromTemplate(viewModel.dateformat)
        cell.date = viewModel.selectedDate
        cell.timezone = timezone
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
        self.feedback.impactOccurred()
        tableView.deselectRow(at: indexPath, animated: true)
        let topIndex = IndexPath(row: 0, section: 0)
        let secondIndex = IndexPath(row: 1, section: 0)
        if indexPath == topIndex {
            let cell = tableView.cellForRow(at: topIndex) as? TimeZoneCell
            self.showDatePicker(formatter: cell?.formatter, timezone: cell?.timezone?.timezone)
            return
        }
        tableView.beginUpdates()
        viewModel.move(at: indexPath, to: topIndex)
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
        if viewModel.timezones.count <= 2 {
            return false
        }
        return true
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        let delete = UITableViewRowAction(style: .normal, title: "Remove ⏰") { [unowned self] (_, indexPath) in
            tableView.beginUpdates()
            self.viewModel.delete(at: indexPath)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
        }

        let share = UITableViewRowAction(style: .normal, title: "Create 🗓") { [weak self] (_, indexPath) in
            guard let cell = tableView.cellForRow(at: indexPath) as? TimeZoneCell else {
                return
            }

            let action = {
                guard let vm = self?.viewModel else { return }
                let vc = EKEventEditViewController()
                let event = EKEvent(eventStore: vm.store)
                event.notes = cell.infoLabel?.text ?? ""
                event.startDate = vm.selectedDate
                event.endDate = vm.selectedDate?.addingTimeInterval(3600)
                event.timeZone = cell.timezone?.timezone
                event.calendar = vm.store.defaultCalendarForNewEvents
                vc.eventStore = vm.store
                vc.event = event
                vc.editViewDelegate = self
                self?.present(vc, animated: true, completion: nil)
            }

            if EKEventStore.authorizationStatus(for: .event) != .authorized {
                self?.viewModel.store.requestAccess(to: .event, completion: { (_, _) in
                    action()
                })
            } else {
                action()
            }
        }

        delete.backgroundColor = UIColor.strawberry()
        share.backgroundEffect = UIBlurEffect(style: .light)
        return [delete, share]
    }
}

extension GlanceViewController: GlanceViewModelOwner {
    var listView: UITableView {
        return self.tableView
    }

    var visiable: Bool {
        return self.presentedViewController == nil
    }
}

extension GlanceViewController: EKEventEditViewDelegate {
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        do {
            try viewModel.store.commit()
            controller.dismiss(animated: true, completion: nil)
        } catch let error {
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            alert.popoverPresentationController?.sourceView = self.view
            alert.popoverPresentationController?.sourceRect = self.view.bounds
            self.present(alert, animated: true, completion: nil)
        }
    }
}

extension GlanceViewController {
    @objc func addTimezone() {
        let vc = TimezonesViewController()
        let nav = UINavigationController(rootViewController: vc)
        self.halfModalTransitioningDelegate = HalfModalTransitioningDelegate(viewController: self, presentingViewController: nav)
        nav.modalPresentationStyle = .custom
        nav.transitioningDelegate = self.halfModalTransitioningDelegate
        self.present(nav, animated: true, completion: nil)
    }

    @objc func showSettings() {
        let vc = SettingsViewController(style: .plain)
        let nav = UINavigationController(rootViewController: vc)
        self.halfModalTransitioningDelegate = HalfModalTransitioningDelegate(viewController: self, presentingViewController: nav)
        nav.modalPresentationStyle = .custom
        nav.transitioningDelegate = self.halfModalTransitioningDelegate
        self.present(nav, animated: true, completion: nil)
    }

    func showDatePicker(formatter: DateFormatter? = nil, timezone: TimeZone? = nil) {
        guard self.picker == nil else { return }

        let picker = DatePicker()
        if let formatter = formatter {
            picker.formatter = formatter
        }
        picker.timezone = timezone
        picker.selectCompletion = { [weak self] date in
            guard let ss = self else { return }
            ss.viewModel.selectedDate = date
            for i in 0..<ss.viewModel.timezones.count {
                let idx = IndexPath(row: i, section: 0)
                guard let cell = ss.tableView.cellForRow(at: idx) as? TimeZoneCell else {
                    continue
                }
                cell.date = date
            }
        }
        picker.showIn(view: self.navigationController?.view, duration: 0.7)
        self.picker = picker
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
        label.text = "We're wasting time here."
        label.textColor = UIColor.black25Percent()
        label.sizeToFit()
        header.addSubview(label)
        header.backgroundColor = UIColor.white
        header.fp_height = height
        label.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-120)
            make.centerX.equalToSuperview()
        }
        let label2 = UILabel()
        label2.text = "Fine."
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
