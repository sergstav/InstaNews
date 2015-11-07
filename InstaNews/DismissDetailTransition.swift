//
//  DismissDetailTransition.swift
//  InstaNews
//
//  Created by sergstav on 11/7/15.
//  Copyright © 2015 nscodegroup. All rights reserved.
//

import UIKit

class DismissDetailTransition : NSObject, UIViewControllerAnimatedTransitioning
{
    func animateTransition(transitionContext: UIViewControllerContextTransitioning)
    {
        let detail = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            detail.view.alpha = 0.0
            }) { (finished: Bool) -> Void in
                detail.view.removeFromSuperview()
                transitionContext.completeTransition(true)
        }
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval
    {
        return 0.5
    }
}
