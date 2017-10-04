//
//  DatePicker.swift
//  AnyTime
//
//  Created by Tao Xu on 9/26/17.
//  Copyright © 2017 Tao Xu. All rights reserved.
//

import Foundation
import SnapKit

class DatePicker: UIView {

    public var selectCompletion: ((Date) -> Void)?

    public var selectedDate: Date? {
        didSet {
            if let date = selectedDate {
                self.dateLabel.text = self.formatter.string(from: date)
                self.picker.setDate(date, animated: true)
            }
        }
    }

    public var formatter = DateFormatter()

    public var timezone: TimeZone? {
        get {
            return picker.timeZone
        }
        set {
            picker.timeZone = newValue
        }
    }

    public func showIn(view: UIView?, duration: TimeInterval = 1) {
        guard let view = view else { return }

        configureSubviews()
        self.overlay.embedded(in: view)
        self.overlay.frame = view.bounds
        self.fp_y = view.fp_height
        self.fp_width = view.fp_width
        view.addSubview(self)
        self.layoutIfNeeded()
        self.overlay.layoutIfNeeded()
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 7, options: .curveEaseIn, animations: {
            self.snp.remakeConstraints({ make in
                make.leading.trailing.bottom.equalToSuperview()
                make.height.equalTo(285)
            })
            view.layoutIfNeeded()
        })
    }

    public func dismiss() {
        UIView.animate(withDuration: 0.2, animations: ({
            self.alpha = 0
        })) { _ in
            self.overlay.removeFromSuperview()
            self.removeFromSuperview()
        }
    }

    @objc func cancelButtonTapped() {
        self.dismiss()
    }

    @objc func nowButtonTapped() {
        self.selectedDate = Date()
    }

    @objc func doneButtonTapped() {
        selectCompletion?(selectedDate ?? Date())
        self.dismiss()
    }

    @objc func dateChanged(_ sender: UIDatePicker) {
        selectedDate = sender.date
    }

    lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(UIColor.black25Percent(), for: .normal)
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        button.sizeToFit()
        return button
    }()

    lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.black25Percent()
        return label
    }()

    lazy var nowButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Today", for: .normal)
        button.addTarget(self, action: #selector(nowButtonTapped), for: .touchUpInside)
        button.setTitleColor(UIColor.black25Percent(), for: .normal)
        button.sizeToFit()
        return button
    }()

    lazy var header: UIStackView = {
        let view = UIStackView()
        view.distribution = .fillProportionally
        view.axis = .horizontal
        return view
    }()

    lazy var picker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        picker.backgroundColor = UIColor.white
        try? ObjC.catchException {
            picker.setValue(UIColor.black25Percent(), forKey: "textColor")
            picker.sendAction(Selector("setHighlightsToday:"), to: nil, for: nil)
        }
        return picker
    }()

    lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Done", for: .normal)
        button.setTitleColor(UIColor.ghostWhite(), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        return button
    }()

    lazy var footer: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        return view
    }()

    lazy var contentView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        return view
    }()

    lazy var overlay: UIView = {
        let overlay = UIView(backgroundColor: UIColor.black)
        overlay.alpha = 0.5
        overlay.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cancelButtonTapped)))
        return overlay
    }()

    func configureSubviews() {

        self.backgroundColor = UIColor.clear
        self.dateLabel.text = self.formatter.string(from: self.selectedDate ?? Date())

        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
        blurView.embedded(in: self)
        contentView.embedded(in: self)

        let headerBg = UIView(backgroundColor: UIColor.iceberg())
        header.embedded(in: headerBg)

        let footerBg = UIView(backgroundColor: UIColor.midnightBlue())
        footer.embedded(in: footerBg)

        header.addArrangedSubview(cancelButton)
        header.addArrangedSubview(dateLabel)
        header.addArrangedSubview(nowButton)

        footer.addArrangedSubview(doneButton)

        contentView.addArrangedSubview(headerBg)
        contentView.addArrangedSubview(picker)
        contentView.addArrangedSubview(footerBg)
    }
}
