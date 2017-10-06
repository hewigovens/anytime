//
//  HalfModalTransitionAnimator.swift
//  HalfModalPresentationController
//
//  Created by Martin Normark on 29/01/16.
//  Copyright © 2016 martinnormark. All rights reserved.
//

import UIKit

class HalfModalTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    var type: HalfModalTransitionAnimatorType
    var transitionCompleted = false
    
    init(type:HalfModalTransitionAnimatorType) {
        self.type = type
    }
    
    @objc func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let from = transitionContext.view(forKey: UITransitionContextViewKey.from)

        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: { () -> Void in
            from!.frame.origin.y = 800
            print("animating...")
            DispatchQueue.main.delay(ms: 450, execute: {
                self.completeTransition(using: transitionContext)
            })

        }) { (completed) -> Void in
            print("animate completed")
            self.completeTransition(using: transitionContext)
        }
    }

    func completeTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if !self.transitionCompleted {
            self.transitionCompleted = true
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }
}

internal enum HalfModalTransitionAnimatorType {
    case Present
    case Dismiss
}
