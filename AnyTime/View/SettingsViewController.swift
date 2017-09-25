//
//  SettingsViewController.swift
//  AnyTime
//
//  Created by Tao Xu on 9/25/17.
//  Copyright © 2017 Tao Xu. All rights reserved.
//

import UIKit
import FontAwesomeKit

class SettingsViewController: UITableViewController {

    let data = [(title: String, items: [[String: String]])]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNaviItems()
        configureSubviews()
    }

    func configureNaviItems() {
        self.title = "Settings"
        let size: CGFloat = 30
        let icon = FAKIonIcons.iosCloseEmptyIcon(withSize: size)
        let image = icon?.image(with: CGSize(width: size, height: size))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(close))
    }
    func configureSubviews() {
        self.tableView.backgroundColor = .clear
        self.tableView.backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    }

    @objc func close() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
}
