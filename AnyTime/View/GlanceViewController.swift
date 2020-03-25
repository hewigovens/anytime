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
    var dragInitialIndexPath: IndexPath?
    var dragCellSnapshot: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.viewModel = GlanceViewModel(owner: self)
        configureNaviItem()
        configureSubviews()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.timezones.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: TimeZoneCell = tableView.dequeueReusableCell(for: indexPath)
        guard let timezone = viewModel.item(at: indexPath) else { return cell }
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
        feedback.impactOccurred()
        tableView.deselectRow(at: indexPath, animated: true)
        let topIndex = IndexPath(row: 0, section: 0)
        let secondIndex = IndexPath(row: 1, section: 0)
        if indexPath == topIndex {
            let cell = tableView.cellForRow(at: topIndex) as? TimeZoneCell
            showDatePicker(formatter: cell?.formatter, timezone: cell?.timezone?.timezone)
            return
        }
        tableView.beginUpdates()
        viewModel.move(at: indexPath, to: topIndex)
        tableView.moveRow(at: indexPath, to: topIndex)
        tableView.endUpdates()
        tableView.reloadRows(at: [topIndex], with: .automatic)
        tableView.reloadRows(at: [secondIndex], with: .top)

        DispatchQueue.main.delay(ms: 500) {
            tableView.scrollToRow(at: topIndex, at: .bottom, animated: true)
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

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteItem = UIContextualAction(style: .normal, title: "Remove ⏰") {  (_, _, _) in
            tableView.beginUpdates()
            self.viewModel.remove(at: indexPath)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
        }
        deleteItem.backgroundColor = UIColor.strawberry()

        let shareItem = UIContextualAction(style: .normal, title: "Create 🗓") {  (_, _, _) in
            guard let cell = tableView.cellForRow(at: indexPath) as? TimeZoneCell else {
                return
            }

            DispatchQueue.main.async {
                let action = {
                    guard let viewModel = self.viewModel else { return }
                    let viewController = EKEventEditViewController()
                    let event = EKEvent(eventStore: viewModel.store)
                    event.notes = "\(cell.infoLabel?.text ?? "") \(cell.timezone?.timezone.abbreviation() ?? "")"
                    event.startDate = viewModel.selectedDate
                    event.endDate = viewModel.selectedDate?.addingTimeInterval(3600)
                    event.timeZone = cell.timezone?.timezone
                    event.calendar = viewModel.store.defaultCalendarForNewEvents
                    viewController.eventStore = viewModel.store
                    viewController.event = event
                    viewController.editViewDelegate = self
                    self.present(viewController, animated: true, completion: nil)
                }

                if EKEventStore.authorizationStatus(for: .event) != .authorized {
                    self.viewModel.store.requestAccess(to: .event, completion: { (_, _) in
                        action()
                    })
                } else {
                    action()
                }
            }
        }

        return UISwipeActionsConfiguration(actions: [deleteItem, shareItem])
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
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}

extension GlanceViewController: UITableViewDropDelegate, UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard viewModel.item(at: indexPath) != nil else { return [] }
        let itemProvider = NSItemProvider()
        return [UIDragItem(itemProvider: itemProvider)]
    }

    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        let to: IndexPath
        if let indexPath = coordinator.destinationIndexPath {
            to = indexPath
        } else {
            // Get last index path of table view.
            let section = tableView.numberOfSections - 1
            let row = tableView.numberOfRows(inSection: section)
            to = IndexPath(row: row, section: section)
        }
        for item in coordinator.items {
            guard let from = item.sourceIndexPath else { continue }
            self.viewModel.move(at: from, to: to)
            tableView.reloadData()
        }
    }

    @objc func addTimezone() {
        let timezonesVC = TimezonesViewController()
        let nav = UINavigationController(rootViewController: timezonesVC)
        self.present(nav, animated: true, completion: nil)
    }

    @objc func showSettings() {
        let settingsVC = SettingsViewController(style: .plain)
        let nav = UINavigationController(rootViewController: settingsVC)
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
            guard let `self` = self else { return }
            self.update(date: date)
        }
        picker.showIn(view: self.navigationController?.view, duration: 0.7)
        self.picker = picker
    }

    func update(date: Date) {
        viewModel.selectedDate = date
        for idx in 0..<viewModel.timezones.count {
            let indexPath = IndexPath(row: idx, section: 0)
            guard let cell = tableView.cellForRow(at: indexPath) as? TimeZoneCell else {
                continue
            }
            cell.date = date
        }
    }

    func configureNaviItem() {
        self.title = "AnyTime"
        let rightSize: CGFloat = 30
        let rightIcon = FAKIonIcons.iosPlusEmptyIcon(withSize: rightSize)
        rightIcon?.addAttribute(NSAttributedString.Key.foregroundColor.rawValue, value: UIColor.black)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: rightIcon?.image(with: CGSize(width: rightSize, height: rightSize)), style: .plain, target: self, action: #selector(addTimezone))

        let leftSize: CGFloat = 24
        let leftIcon = FAKIonIcons.iosGearOutlineIcon(withSize: leftSize)
        rightIcon?.addAttribute(NSAttributedString.Key.foregroundColor.rawValue, value: UIColor.black)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: leftIcon?.image(with: CGSize(width: leftSize, height: leftSize)), style: .plain, target: self, action: #selector(showSettings))
    }

    func configureSubviews() {
        tableView.register(cellType: TimeZoneCell.self)
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.midnightBlue()
        tableView.tableFooterView = UIView()
        tableView.dragInteractionEnabled = true
        tableView.dragDelegate = self
        tableView.dropDelegate = self

        configureHeader()
    }

    func configureHeader() {
        let height: CGFloat = 550
        tableView.tableHeaderView = self.createHeader(height: height)
        tableView.contentInset = UIEdgeInsets(top: -height, left: 0, bottom: 0, right: 0)
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
