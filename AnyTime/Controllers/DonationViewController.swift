//
//  DonationViewController.swift
//  AnyTime
//
//  Created by Tao Xu on 9/30/17.
//  Copyright © 2017 Tao Xu. All rights reserved.
//

import UIKit
import NotificationBannerSwift

class DonationViewController: UIViewController {

    let donationAddress = "3QPU2iYbFAT8HBsxVGhjFpfGXrdbYNaT1s"

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubviews()
    }

    func configureSubviews() {
        self.view.backgroundColor = .iceberg()

        let button = UIButton(type: .system)
        button.setTitle(self.donationAddress, for: .normal)
        button.setTitleColor(.black25Percent(), for: .normal)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: .regular)
        button.addTarget(self, action: #selector(copyAddress), for: .touchUpInside)
        button.embedded(in: self.view) { make in
            make.center.equalToSuperview()
        }

        guard let code = QRCode(self.donationAddress) else { return }
        let image = UIImageView(qrCode: code)
        image.embedded(in: self.view, make: { make in
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 128, height: 128))
            make.bottom.equalTo(button.snp.top).offset(-20)
        })
    }

    @objc func copyAddress() {
        UIPasteboard.general.string = self.donationAddress
        let banner = NotificationBanner(title: "Bitcoin address copied.", style: .success)
        banner.duration = 1
        banner.show()
    }
}
