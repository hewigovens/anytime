//
//  FormatEditorViewController.swift
//  AnyTime
//
//  Created by Tao Xu on 9/30/17.
//  Copyright © 2017 Tao Xu. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import NotificationBannerSwift

class FormatEditorViewController: UIViewController, HalfModalPresentable {

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    lazy var input: UITextField = {
        let input = UITextField()
        let title = UILabel()
        title.text = " Date Format: "
        title.textColor = UIColor.black25Percent()
        title.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .light)
        title.sizeToFit()
        input.leftView = title
        input.leftViewMode = .always
        input.clearButtonMode = .always
        input.backgroundColor = UIColor.white
        input.text = Defaults[.format]
        input.textColor = UIColor.black25Percent()
        input.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .regular)
        input.autocorrectionType = .no
        input.returnKeyType = .done
        return input
    }()

    lazy var previewLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: .regular)
        label.textColor = UIColor.black25Percent()
        label.textAlignment = .center
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubviews()
        updatePreview()
        DispatchQueue.main.delay(ms: 500) {
            self.maximizeToFullScreen()
        }
        _ = NotificationCenter.default.addObserver(forName: Notification.Name.UITextFieldTextDidChange, object: input, queue: OperationQueue.main) { [weak self] _ in
            self?.updatePreview()
        }
    }

    func configureSubviews() {
        self.view.backgroundColor = UIColor.iceberg()

        input.embedded(in: self.view) { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(30)
            make.height.equalTo(50)
        }

        previewLabel.embedded(in: self.view) { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.input.snp.bottom).offset(10)
        }

        input.delegate = self
        input.becomeFirstResponder()
    }

    func updatePreview() {
        guard let input = input.text else {
            self.previewLabel.text = ""
            return
        }
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate(input)
        self.previewLabel.text = formatter.string(from: Date())
    }

    func persistFormat() {
        guard let text = self.previewLabel.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            text.length > 0 else {
            return
        }
        guard let format = self.input.text, format.length > 0 else {
            return
        }
        Defaults.set(.format, format)
        Defaults.synchronize()

        let banner = NotificationBanner(title: "Date format updated.", style: .success)
        banner.duration = 1
        banner.show()
    }
}

extension FormatEditorViewController: UITextFieldDelegate {
    @objc func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.persistFormat()
        return true
    }
}
