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

import Foundation

public struct Products {
    
    public static let Annual = "uk.co.bottledlogic.subscripto.app.year"
    public static let Monthly = "uk.co.bottledlogic.subscripto.app.month"
    
    public static let productIdentifiers: Set<ProductIdentifier> = [Products.Annual, Products.Monthly]
    public static var store: IAPHelper!
    
    public static func actionPurchase(_ productIdentifier: String){
        guard let vcSingleton = ViewController.singletonSelf else {
            return print("Error: IAPHelper unable to get ViewController's singleton self to re-enact removeAd() call.")
        }
        
        switch(productIdentifier){
            case Products.Annual:
                // UserDefaults.standard.set(true, forKey: Products.Annual)
                vcSingleton.annualSubscriptionConfirmed()
            case Products.Monthly:
                // UserDefaults.standard.set(true, forKey: Products.Monthly)
                vcSingleton.monthlySubscriptionConfirmed()
            default: return;
        }
    }
}

func resourceNameForProductIdentifier(_ productIdentifier: String) -> String? {
    return productIdentifier.components(separatedBy: ".").last
}
