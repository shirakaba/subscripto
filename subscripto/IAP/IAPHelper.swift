/*
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import StoreKit

public typealias ProductIdentifier = String
public typealias ProductsRequestCompletionHandler = (_ products: [SKProduct]?, _ error: Error?) -> ()

open class IAPHelper : NSObject  {
    
    static let IAPHelperPurchaseNotification = "IAPHelperPurchaseNotification"
    fileprivate let productIdentifiers: Set<ProductIdentifier>
    // fileprivate var purchasedProductIdentifiers = Set<ProductIdentifier>()
    fileprivate var productsRequest: SKProductsRequest?
    fileprivate var productsRequestCompletionHandler: ProductsRequestCompletionHandler?
    fileprivate var paymentStatusUI: PaymentStatusUI?
    let receiptValidator = ReceiptValidator()
    
    public init(productIds: Set<ProductIdentifier>) {
        productIdentifiers = productIds
//        for productIdentifier in productIds {
//            if(UserDefaults.standard.bool(forKey: productIdentifier)){
//                print("Previously purchased: \(productIdentifier)")
//                purchasedProductIdentifiers.insert(productIdentifier)
//            } else {
//                print("Not yet purchased: \(productIdentifier)")
//            }
//        }
        super.init()
    }
    
    public func registerVC(_ vc: PaymentStatusUI){ self.paymentStatusUI = vc; }
    public func deregisterVC(){ self.paymentStatusUI = nil; }
}

// MARK: - StoreKit API
extension IAPHelper {
    public func requestProducts(completionHandler: @escaping ProductsRequestCompletionHandler) {
        print("requestProducts() called.")
        productsRequest?.cancel()
        productsRequestCompletionHandler = completionHandler
        
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest!.delegate = self
        productsRequest!.start()
    }
    
    public func buyProduct(_ product: SKProduct) {
        print("Buying \(product.productIdentifier)...")
        self.paymentStatusUI?.callPKHUD(.labeledProgress(title: "Connecting to App Store...", subtitle: "Please wait."), dimsBackground: true)
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
//    public func isProductPurchased(_ productIdentifier: ProductIdentifier) -> Bool {
//        print("Entering isProductPurchased().")
//        return purchasedProductIdentifiers.contains(productIdentifier)
//    }
    
    public class func canMakePayments() -> Bool {
        print("Entering canMakePayments().")
        return SKPaymentQueue.canMakePayments()
    }
    
    public func restorePurchases() {
        print("Entering restorePurchases().")
        self.paymentStatusUI?.callPKHUD(.labeledProgress(title: "Restoring purchases...", subtitle: "Please wait."), dimsBackground: true)
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}

// MARK: - SKProductsRequestDelegate
extension IAPHelper: SKProductsRequestDelegate {
    // Calls the callback 'productsRequestCompletionHandler', passed in for example by a customer-facing VC (eg. MasterViewController), with:
    // 1) An indication of success (true); and: 2) Our list of products, with which it can fill its table.
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let products = response.products
        print("Loaded list of products...")
        productsRequestCompletionHandler?(products, nil)
        clearRequestAndHandler()
        
        for p in products {
            print("Found product: \(p.productIdentifier) \(p.localizedTitle) \(p.price.floatValue)")
        }
    }
    
    // Calls the callback 'productsRequestCompletionHandler', passed in for example by a customer-facing VC (eg. MasterViewController), with:
    // 1) An indication of success (false); and: 2) A nil list of products.
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Failed to load list of products.")
        print("Error: \(error.localizedDescription)")
        productsRequestCompletionHandler?(nil, error)
        clearRequestAndHandler()
    }
    
    private func clearRequestAndHandler() {
        print("Entering clearRequestAndHandler().")
        productsRequest = nil
        productsRequestCompletionHandler = nil
    }
}

// MARK: - SKPaymentTransactionObserver
extension IAPHelper: SKPaymentTransactionObserver {
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        print("paymentQueue got called! paymentStatusUI is: \(String(describing: paymentStatusUI))")
        self.paymentStatusUI?.callPKHUD(.labeledProgress(title: "Processing transactions...", subtitle: "Please wait."), dimsBackground: true)
        
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .purchased:
                complete(transaction: transaction)
                break
            case .failed:
                fail(transaction: transaction)
                break
            case .restored:
                restore(transaction: transaction)
                break
            case .deferred:
                deferred(transaction: transaction)
                break
            case .purchasing:
                purchasing(transaction: transaction)
                break
            }
        }
    }
    
    // The transaction is in the queue, but its final status is pending external action such as Ask to Buy. Update your UI to show the deferred state, and wait for another callback that indicates the final status.
    // eg. https://stackoverflow.com/questions/27326836/what-is-the-skpaymenttransactionstatedeferred-flow-of-alert-messages-by-apple
    private func deferred(transaction: SKPaymentTransaction){
        guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }
        
        print("deferred... \(productIdentifier)")
        self.paymentStatusUI?.callPKHUD(.labeledProgress(title: "Transaction pending...", subtitle: "Please wait."), dimsBackground: true)
    }
    
    // The transaction is being processed by the App Store.
    private func purchasing(transaction: SKPaymentTransaction){
        guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }
        
        print("purchasing... \(productIdentifier)")
        self.paymentStatusUI?.callPKHUD(.labeledProgress(title: "Transaction in progress...", subtitle: "Please wait."), dimsBackground: true)
    }
    
    // Before finishTransaction(), persist the purchase and apply it.
    // https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/StoreKitGuide/Chapters/DeliverProduct.html#//apple_ref/doc/uid/TP40008267-CH5-SW10
    private func complete(transaction: SKPaymentTransaction) {
        print("complete...")
       
        // This receipt check is only necessary to set a one-month or one-year timer for checking whether the subscription period renewed successfully.
        notifyOfPurchaseUnlessExpired(transaction.payment.productIdentifier, "[just now]")
        self.paymentStatusUI?.hidePKHUD()
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func notifyOfPurchaseUnlessExpired(_ productIdentifier: String, _ dateStr: String) {
        switch productIdentifier {
        case Products.Annual, Products.Monthly:
            print("[IAPHelper.restore()] Examining receipt for \(productIdentifier) with transactionDate \(dateStr)")
            let validationResult = receiptValidator.validateReceipt()
            switch validationResult {
            case .success(let parsedReceipt):
                print("[IAPHelper.restore()] Local receipt validation succeeded! Checking parsed receipt now.")
                let subscriptionActive: Bool = ViewController.checkParsedReceipt(parsedReceipt)
                if(subscriptionActive){
                    deliverPurchaseNotificationFor(identifier: productIdentifier)
                    Products.actionPurchase(productIdentifier)
                } else {
                    print("[IAPHelper.restore()] Suppressing sending any purchase notification when restoring this subscription period of \(productIdentifier), as it has expired.")
                }
            case .error(let error):
                print("[IAPHelper.restore()] Error with receipt: \(error)")
            }
        default:
            print("[IAPHelper.restore()] No need to examine receipt for \(productIdentifier) with transactionDate \(dateStr), as it is not a subscription.")
            deliverPurchaseNotificationFor(identifier: productIdentifier)
            Products.actionPurchase(productIdentifier)
            break
        }
    }
    
    /* RW Selfies app seems to suggest that the local receipt gets updated upon each transaction, so we can verify here. */
    private func restore(transaction: SKPaymentTransaction) {
        guard let original = transaction.original else { return }
        let productIdentifier = original.payment.productIdentifier
        
        var dateStr: String = "nil"
        if let date = original.transactionDate { dateStr = date.description }
        
        notifyOfPurchaseUnlessExpired(productIdentifier, dateStr)
        
        self.paymentStatusUI?.hidePKHUD()
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func fail(transaction: SKPaymentTransaction) {
        print("fail...")
        
        self.paymentStatusUI?.hidePKHUD()
        if let transactionError = transaction.error as? NSError {
            if transactionError.code != SKError.paymentCancelled.rawValue {
                print("Transaction Error: \(String(describing: transaction.error?.localizedDescription))")
            }
        }
        
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    /* Adds the purchased/restored item to the list of purchased products, and archives the purchase in Strongbox.
     * Also sends a notification (fires an event) of the purchase completion, which can be listened to by dependents,
     * eg. so that the UI can be updated accordingly. */
    private func deliverPurchaseNotificationFor(identifier: String?) {
        guard let identifier = identifier else { return }
        print("Entering deliverPurchaseNotificationFor()...")
        
        // purchasedProductIdentifiers.insert(identifier)
        // UserDefaults.standard.set(true, forKey: identifier)
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: IAPHelper.IAPHelperPurchaseNotification), object: identifier)
    }
}

