//
//  ViewController.swift
//  subscripto
//
//  Created by jamie on 29/11/2018.
//  Copyright © 2018 Bottled Logic. All rights reserved.
//

import UIKit
import PKHUD
import StoreKit

class ViewController: UIViewController {
    static var singletonSelf: ViewController?
    
    var viewSetupCompleted: Bool = false
    
    let receiptValidator = ReceiptValidator()
    var receiptRequest: SKReceiptRefreshRequest!

    override func loadView() {
        super.loadView()
        // Do any additional setup after loading the view, typically from a nib.
        
        ViewController.singletonSelf = self
        validateReceipt()
    }
    
    /* On ViewController's ViewDidAppear hook, check subscription status and present this if necessary. */
    func onSubscriptionInactive(){
        self.view.backgroundColor = UIColor.yellow
        let alertController: UIAlertController = UIAlertController(
            title: "Subscription inactive",
            message: "Subscripto requires a subscription to operate. Please go to the shop to start a new subscription (or restore existing purchases), or discontinue use of the app.",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "Go to shop", style: .default, handler: { (action: UIAlertAction) -> Void in
            self.goToShop()
        }))
        alertController.addAction(UIAlertAction(title: "Refresh receipts", style: .default, handler: { (action: UIAlertAction) -> Void in
            print("Sending another receipt request...")
            HUD.show(HUDContentType.labeledProgress(title: "Refreshing receipts...", subtitle: nil))
            self.receiptRequest = SKReceiptRefreshRequest()
            self.receiptRequest.delegate = self
            self.receiptRequest.start()
        }))
        
        if let vc = navigationController?.visibleViewController as? SubscriptionShop {
            return print("User is already at the subscription shop (\(vc.debugDescription)); best not to interrupt them.")
        } else {
            return self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func goToShop(){
        let vc: SubscriptionShop = SubscriptionShop()
        vc.modalPresentationStyle = .custom
        self.providesPresentationContextTransitionStyle = true
        self.definesPresentationContext = true
        self.navigationController!.pushViewController(vc, animated: true)
    }
    
    func annualSubscriptionConfirmed(){
        // Unused callback from Products.actionPurchase()
    }
    
    func monthlySubscriptionConfirmed(){
        // Unused callback from Products.actionPurchase()
    }
    
    func onAccessPermitted(){
        guard !self.viewSetupCompleted else { return; }
        self.view.backgroundColor = UIColor.green
        self.viewSetupCompleted = true
    }
    
    func onReceiptError(_ error: ReceiptValidationError){
        self.view.backgroundColor = UIColor.yellow
        print("ReceiptValidationError when checking local receipt: \(error)")
        var title: String
        // let prompt: String = "you may be prompted to log in to the iTunes Store while we request up-to-date receipts to verify your subscription status."
        let message: String = "LingaBrowse requires a subscription to operate, but no purchase history was found.\n\nPress 'Refresh receipts' to refresh purchase history, or 'Go to shop' to restore purchases or start a new subscription.\n\nYou may be prompted to log in to the iTunes Store."
        switch(error){
        case .couldNotFindReceipt:
            title = "No purchase history found"
        case .emptyReceiptContents:
            title = "Purchase history empty"
        case .receiptNotSigned, .appleRootCertificateNotFound, .receiptSignatureInvalid, .malformedReceipt, .malformedInAppPurchaseReceipt, .incorrectHash:
            fallthrough
        default:
            title = "Purchase history invalid"
        }
        /* https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateLocally.html
         * TODO: On macOS, should exit with status of 173; on iOS, refreshing the receipt is appropriate. */
        let alertController: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Go to shop", style: .default, handler: { (action: UIAlertAction) -> Void in
            self.goToShop()
        }))
        alertController.addAction(UIAlertAction(title: "Refresh receipts", style: .default, handler: { (action: UIAlertAction) -> Void in
            print("User requested to refresh receipts...")
            HUD.show(HUDContentType.labeledProgress(title: "Refreshing receipts...", subtitle: nil))
            self.receiptRequest = SKReceiptRefreshRequest()
            self.receiptRequest.delegate = self
            self.receiptRequest.start()
        }))
        self.present(alertController, animated: true, completion: nil)
    }


    static func checkParsedReceipt(_ receipt: ParsedReceipt) -> Bool {
        print("Parsed receipt, with expirationDate: \(String(describing: receipt.expirationDate))!")
        
        guard let iaps: [ParsedInAppPurchaseReceipt] = receipt.inAppPurchaseReceipts else {
            print("Unable to unwrap receipt.inAppPurchaseReceipts")
            return false
        }
        
        let subscriptionActive: Bool = iaps.contains(where: {
            guard let id: String = $0.productIdentifier,
                (id == Products.Annual || id == Products.Monthly),
                /* https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ReceiptFields.html
                 * Treat a canceled receipt the same as if no purchase had ever been made.
                 * Note: A canceled in-app purchase remains in the receipt indefinitely. Only applicable if the refund was for a non-consumable product, an auto-renewable subscription, a non-renewing subscription, or for a free subscription. */
                $0.cancellationDate == nil,
                let originalPurchaseDate = $0.originalPurchaseDate,
                let subscriptionExpirationDate = $0.subscriptionExpirationDate,
                subscriptionExpirationDate.timeIntervalSinceNow.sign == .plus // https://developer.apple.com/documentation/foundation/nscalendar/1417649-isdate
                else { return false }
            //            if(subscriptionExpirationDate.timeIntervalSinceNow <= 60 * 60 * 24){ // 270 for freshly-purchased 1-Month Plan
            //                HUD.flash(HUDContentType.label("Note: If auto-renew is off, subscription will expire at: \(subscriptionExpirationDate.description(with: Locale.current))"), delay: 5)
            //            }
            if ViewController.singletonSelf!.recheckDate == nil || subscriptionExpirationDate.addingTimeInterval(10) > ViewController.singletonSelf!.recheckDate! {
                /* Shows an alert offering to refresh receipts or go to shop. If already in Subscription Shop, pushes another Subscription Shop VC on top (and nav controller will focus on that).
                 * If user presses Back on both shops, ViewDidAppear will call validateReceipt() anyway. */
                ViewController.singletonSelf!.recheckDate = subscriptionExpirationDate.addingTimeInterval(10)
                RunLoop.main.add(
                    Timer(fireAt: ViewController.singletonSelf!.recheckDate!, interval: 0, target: ViewController.singletonSelf!, selector: #selector(ViewController.validateReceipt), userInfo: nil, repeats: false),
                    forMode: .commonModes
                )
            }
            
            print("[ViewController.checkParsedReceipt] Subscription purchased on \(originalPurchaseDate.description) confirmed to be active. Expires \(subscriptionExpirationDate.description).")
            Products.actionPurchase(id)
            return true
        })
        /* It seems that every hour, 'annual' gains a new iap, where the purchaseDate is one hour later than the (common) originalPurchaseDate and so too is the subscriptionExpirationDate (each one expires an hour after its purchaseDate). This will probably proceed for a whole 12 hours. */
        iaps.forEach({
            guard let id: String = $0.productIdentifier else { return }
            print("Receipt contained productIdentifier: \(id)")
            print("[\(id)]: subscriptionExpirationDate \(String(describing: $0.subscriptionExpirationDate))")
            print("[\(id)]: cancellationDate \(String(describing: $0.cancellationDate))")
            print("[\(id)]: purchaseDate \(String(describing: $0.purchaseDate))")
            print("[\(id)]: originalPurchaseDate \(String(describing: $0.originalPurchaseDate))\n")
        })
        
        return subscriptionActive
    }
    
    // https://stackoverflow.com/questions/45615106/when-to-refresh-a-receipt-vs-restore-purchases-in-ios
    // https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateLocally.html
    @objc func validateReceipt(){
        let validationResult = receiptValidator.validateReceipt()
        
        switch validationResult {
        case .success(let parsedReceipt /*: ParsedReceipt */):
            print("Local receipt validation succeeded! Checking parsed receipt now.")
            let subscriptionActive: Bool = ViewController.checkParsedReceipt(parsedReceipt)
            if(subscriptionActive){
                // Enable app features
                onAccessPermitted()
            } else {
                onSubscriptionInactive()
            }
        case .error(let error /*: ReceiptValidationError */):
            onReceiptError(error)
        }
    }
    var recheckDate: Date? = nil
}

/* https://www.andrewcbancroft.com/2015/10/13/loading-a-receipt-for-validation-with-swift/
 * https://stackoverflow.com/questions/39656700/when-is-ios-app-receipt-not-available */
extension ViewController: SKRequestDelegate {
    public func requestDidFinish(_ request: SKRequest) {
        HUD.hide()
        let validationResult = receiptValidator.validateReceipt()
        switch validationResult {
        case .success(let parsedReceipt):
            print("requested receipt validation succeeded! Checking parsed receipt now.")
            let subscriptionActive: Bool = ViewController.checkParsedReceipt(parsedReceipt)
            if(subscriptionActive){
                onAccessPermitted()
            } else {
                onSubscriptionInactive()
            }
        case .error(let receiptValidationError):
            onReceiptError(receiptValidationError)
        }
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        print("request for receipt failed! \(error.localizedDescription)")
        HUD.hide()
        print(error.localizedDescription)
        
        let alertController: UIAlertController = UIAlertController(title: "Receipt refresh failed", message: "Error: \"\(error.localizedDescription)\".", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Go to shop", style: .default, handler: { (action: UIAlertAction) -> Void in
            self.goToShop()
        }))
        alertController.addAction(UIAlertAction(title: "Refresh receipts again", style: .default, handler: { (action: UIAlertAction) -> Void in
            print("User requested to refresh receipts again...")
            HUD.show(HUDContentType.labeledProgress(title: "Refreshing receipts...", subtitle: nil))
            self.receiptRequest = SKReceiptRefreshRequest()
            self.receiptRequest.delegate = self
            self.receiptRequest.start()
        }))
        self.present(alertController, animated: true, completion: nil)
    }
}
