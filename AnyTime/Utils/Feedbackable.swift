//
//  Feedbackable.swift
//  Inspect
//
//  Created by hewig on 5/8/16.
//  Copyright © 2016 fourplex. All rights reserved.
//

import UIKit
import MessageUI

let kFeedbackRecipient = "support@fourplex.in"
let kFeedbackSubject = "AnyTime Feedback"

protocol Feedbackable {
    var mailToString: String { get }
    var canSendMail: Bool { get }
    func feedbackWithEmail()
    func feedbackWithMailTo()
}

extension SettingsViewController: Feedbackable, MFMailComposeViewControllerDelegate {

    var canSendMail: Bool {
        return MFMailComposeViewController.canSendMail()
    }

    var mailToString: String {
        if let mailTo = "mailto:\(kFeedbackRecipient)?subject=\(kFeedbackSubject)"
            .addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
            return mailTo
        } else {
            return ""
        }
    }

    func feedbackWithEmail() {
        guard MFMailComposeViewController.canSendMail() else {
            return
        }
        let controller = MFMailComposeViewController()
        controller.setToRecipients([kFeedbackRecipient])
        controller.setSubject(kFeedbackSubject)
        controller.mailComposeDelegate = self
        self.present(controller, animated: true, completion: nil)
    }

    func feedbackWithMailTo() {
        if let url = URL(string: self.mailToString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    // MARK: MFMailComposeViewControllerDelegate
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.dismiss(animated: true, completion: nil)
    }
}
