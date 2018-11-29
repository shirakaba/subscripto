//
//  ValidateReceipts.swift
//  pinyinjector
//
//  Created by jamie on 06/11/2018.
//  Copyright © 2018 Jamie Birch. All rights reserved.
//

import Foundation
import StoreKit

/* https://stackoverflow.com/questions/43146453/ios-receipt-not-found :
   There is no receipt until the user makes a purchase. For an app downloaded from the App Store (even a free one).
   This is a purchase, so there will be a receipt.
   For a debug build from Xcode there is no receipt until an in-app purchase is made.
 */
func validateReceipts(){
    let receiptValidator = ReceiptValidator()
    let validationResult = receiptValidator.validateReceipt()
    
    switch validationResult {
    case .success(let receipt):
        print(receipt)
        // Work with parsed receipt data. Possibilities might be...
        // enable a feature of your app
        // remove ads
    // etc...
    case .error(let error):
        print(error)
        // Handle receipt validation failure. Possibilities might be...
        // use StoreKit to request a new receipt
        // enter a "grace period"
        // disable a feature of your app
        // etc...
        let receiptRefresher: ReceiptRefresher = ReceiptRefresher()
        receiptRefresher.skReceiptRefreshReq.start()
    }
}

class ReceiptRefresher: NSObject, SKRequestDelegate {
    let skReceiptRefreshReq: SKReceiptRefreshRequest = SKReceiptRefreshRequest()
    
    override init(){
        super.init()
        
        skReceiptRefreshReq.delegate = self
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("SKReceiptRefreshRequest failed with error: \(error.localizedDescription)")
    }
    
    func requestDidFinish(_ request: SKRequest) {
        print("SKReceiptRefreshRequest finished, returning SKRequest")
    }
}
