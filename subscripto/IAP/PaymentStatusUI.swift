//
//  PaymentStatusUI.swift
//  pinyinjector
//
//  Created by jamie on 03/10/2017.
//  Copyright © 2017 Jamie Birch. All rights reserved.
//

import Foundation
import PKHUD

public protocol PaymentStatusUI {
    func callPKHUD(_ content: HUDContentType, dimsBackground: Bool)
    func hidePKHUD()
}
