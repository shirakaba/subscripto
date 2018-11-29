//
//  SubscriptionShop.swift
//  pinyinjector
//
//  Created by jamie on 09/11/2018.
//  Copyright © 2018 Jamie Birch. All rights reserved.
//

import UIKit
import StoreKit
import PKHUD
import SafariServices

class SubscriptionShop: UIViewController {
    var products = [SKProduct]()
    let section1SV: UIStackView = SectionUI.initSection(spacing: 8, backgroundColor: nil, margins: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
    let monthlySection = SectionUI.initSection(axis: .vertical, alignment: .center, distribution: .fill, spacing: 8, backgroundColor: nil, margins: UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0))
    let annualSection = SectionUI.initSection(axis: .vertical, alignment: .center, distribution: .fill, spacing: 8, backgroundColor: nil, margins: UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0))
    let monthlyPlanButton: UIButton = UIButton(type: .system)
    let annualPlanButton: UIButton = UIButton(type: .system)
    let monthlyPrice: UILabel = UILabel()
    let annualPrice: UILabel = UILabel()
    var pp: UITextView!
    var tos: UITextView!
    let agreePPToSButton: UISwitch = UISwitch()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Subscription Shop"
        
        guard Products.productIdentifiers.count > 0 else {
            return self.callPKHUD(.label("Currently no products; please return to menu."), dimsBackground: false)
        }
            
        /* We'll only display the Restore button if there are > 0 products to restore. */
        let restoreButton = UIBarButtonItem(title: "Restore",
                                            style: .plain,
                                            target: self,
                                            action: #selector(SubscriptionShop.restoreTapped(_:)))
        navigationItem.rightBarButtonItem = restoreButton
        
        /* We'll only bother subscribing for notifications about reloading the purchase state in the table if there is more
         * than one product on sale. */
        // Observes for notifications from IAPHelper's deliverPurchaseNotificationFor(identifier: String?) method, which is
        // called upon the complete() or restore() steps of any SKPaymentTransaction.
        //
        // Upon such notification, handlePurchaseNotification() makes the tableView reload corresponding products' cells.
        NotificationCenter.default.addObserver(self, selector: #selector(SubscriptionShop.handlePurchaseNotification(_:)),
                                               name: NSNotification.Name(rawValue: IAPHelper.IAPHelperPurchaseNotification),
                                               object: nil)
        
        let scrollView: UIScrollView = UIScrollView()
        // scrollView.backgroundColor = UIColor(white: 0.96, alpha: 1)
        scrollView.backgroundColor = UIColor.white
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        let contentSV = SectionUI.initSection(axis: .vertical, alignment: .center, distribution: .fill, spacing: 40.0, backgroundColor: nil, margins: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
        contentSV.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentSV)
        
        contentSV.addArrangedSubview(setUpSection1())
        
        let vd = ["scrollView" : scrollView, "contentSV" : contentSV] as [String : Any]
        SectionUI.constrain(view, vd, H: ["[scrollView]"], V: ["[scrollView]"])
        SectionUI.constrain(scrollView, vd, H: ["[contentSV]"], V: ["[contentSV]"])
        scrollView.addConstraint(NSLayoutConstraint(item: scrollView, attribute: .width, relatedBy: .equal, toItem: contentSV, attribute: .width, multiplier: 1, constant: 0.0))
    }
    
    func setUpSection1() -> UIStackView {
        let title: UILabel = UILabel()
        title.text = "Choose a Plan"
        title.textAlignment = .center
        title.font = UIFont.preferredFont(forTextStyle: .title1)
        
        let intro: UILabel = UILabel()
        intro.numberOfLines = 0
        intro.lineBreakMode = .byWordWrapping
        intro.text = "Please choose a subscription plan to activate Subscripto."
        intro.font = UIFont.preferredFont(forTextStyle: .body)
        
        monthlyPlanButton.setAttributedTitle(
            NSMutableAttributedString(
                string: "1-Month Plan\n(1-month FREE trial)",
                // attributes: [NSAttributedStringKey.font : UIFont.preferredFont(forTextStyle: .title1)]
                attributes: [NSAttributedStringKey.font : UIFont.preferredFont(forTextStyle: .headline)]
            ),
            for: .normal
        )
        // annualPlanButton.titleLabel?.text = "1-Month Plan\n(1-month trial)"
        monthlyPlanButton.tag = 1
        stylePlanButton(monthlyPlanButton)
        monthlyPlanButton.addTarget(self, action: #selector(buttonsFn(sender:)), for: .touchUpInside)
        
        annualPlanButton.setAttributedTitle(
            NSMutableAttributedString(
                string: "12-Month Plan\n(1-month FREE trial)",
                // attributes: [NSAttributedStringKey.font : UIFont.preferredFont(forTextStyle: .title1)]
                attributes: [NSAttributedStringKey.font : UIFont.preferredFont(forTextStyle: .headline)]
            ),
            for: .normal
        )
        // annualPlanButton.titleLabel?.text = "12-Month Plan\n(1-month trial)"
        annualPlanButton.tag = 2
        annualPlanButton.contentEdgeInsets = UIEdgeInsetsMake(8, 16, 8, 16)
        stylePlanButton(annualPlanButton)
        annualPlanButton.addTarget(self, action: #selector(buttonsFn(sender:)), for: .touchUpInside)
        
        monthlyPrice.text = "Renews for ____ every month"
        monthlyPrice.textAlignment = .center
        monthlyPlanButton.contentEdgeInsets = UIEdgeInsetsMake(8, 16, 8, 16)
        // monthlyPrice.font = UIFont.preferredFont(forTextStyle: .title2)
        monthlyPrice.font = UIFont.preferredFont(forTextStyle: .subheadline)
        
        annualPrice.text = "Renews for ____ every year"
        annualPrice.textAlignment = .center
        // annualPrice.font = UIFont.preferredFont(forTextStyle: .title2)
        annualPrice.font = UIFont.preferredFont(forTextStyle: .subheadline)
        
        let disclaimer: UITextView = SubscriptionShop.makeTextView(delegate: self)
        disclaimer.font = UIFont.preferredFont(forTextStyle: .footnote)
        disclaimer.textColor = UIColor.gray
        disclaimer.text = "Subscripto requires a paid subscription, and subscriptions cannot currently be shared across platforms (i.e. mobile and desktop versions will require separate plans). Monthly and yearly subscription plans are offered, each including a fully-functional one-month trial. They are called \"1-Month Plan (1-month trial)\" and \"12-Month Plan (1-month trial)\" respectively, in English localisation; and may have corresponding translated names in other localisations. Pricing in other countries or territories may vary and charges may be converted to your local currency.\n\nIf you choose to purchase a subscription for Subscripto, payment will be charged to your iTunes account, and your account will be charged for renewal 24 hours prior to the end of the current period; the charge will be as described by the product. Auto-renewal may be turned off at any time by going to your Account Settings in the iTunes Store after purchase.\n\nAfter your Subscripto free trial ends, your account will be charged unless your subscription is cancelled more than 24 hours before the end of your trial period. Any unused portion of a free trial period, if offered, will be forfeited upon subscription purchase."
        
//        let ppTos = SectionUI.initSection(axis: .vertical, alignment: .center, distribution: .fill, spacing: 8, backgroundColor: nil, margins: UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0))
//
//        pp = AgreementsVC.makeTextView(delegate: self)
//        pp.attributedText = makeAttributedText(hyperlinkedArea: "Privacy Policy", fullString: "Privacy Policy", url: "http://birchlabs.co.uk/Subscripto/infopages/privacy.html")
//        pp.textAlignment = .center
//
//        tos = AgreementsVC.makeTextView(delegate: self)
//        tos.textAlignment = .center
//        tos.attributedText = makeAttributedText(hyperlinkedArea: "Terms of Service", fullString: "Terms of Service", url: "http://birchlabs.co.uk/Subscripto/infopages/tos.html")

//        let agreePPToSLabel = UILabel()
//        agreePPToSLabel.text = "I agree to the Terms of Service and Privacy Policy"
//        agreePPToSLabel.font = UIFont.preferredFont(forTextStyle: .body)
        
        let ppTosContainer = UIView()
        
        let agreePPToSTextView = SubscriptionShop.makeTextView(delegate: self)
        agreePPToSTextView.textAlignment = .center
        let fullString: String = "I agree to the Terms of Service and Privacy Policy."
        let attributedText: NSMutableAttributedString = NSMutableAttributedString(string: fullString)
        attributedText.addAttributes([NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .body)], range: (fullString as NSString).range(of: fullString))
        attributedText.addAttributes([NSAttributedStringKey.link: "https://birchlabs.co.uk/subscripto/infopages/tos.html"], range: (fullString as NSString).range(of: "Terms of Service"))
        attributedText.addAttributes([NSAttributedStringKey.link: "https://birchlabs.co.uk/subscripto/infopages/privacy.html"], range: (fullString as NSString).range(of: "Privacy Policy"))
        agreePPToSTextView.attributedText = attributedText
        
        agreePPToSButton.setOn(false, animated: false) // Opt-in, so init as false
        agreePPToSButton.addTarget(self, action: #selector(agreePPToSFn(_:)), for: .valueChanged)
        agreePPToSButton.onTintColor = UIColor.gray
        
        agreePPToSTextView.translatesAutoresizingMaskIntoConstraints = false
        agreePPToSButton.translatesAutoresizingMaskIntoConstraints = false
        agreePPToSButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 751), for: .horizontal)
        
        ppTosContainer.addSubview(agreePPToSTextView)
        ppTosContainer.addSubview(agreePPToSButton)
        
        NSLayoutConstraint.activate(
            [
                agreePPToSTextView.topAnchor.constraint(equalTo: ppTosContainer.topAnchor),
                agreePPToSTextView.bottomAnchor.constraint(equalTo: ppTosContainer.bottomAnchor),
                agreePPToSTextView.leftAnchor.constraint(equalTo: ppTosContainer.leftAnchor),
                // agreePPToSTextView.rightAnchor.constraint(equalTo: agreePPToSButton.leftAnchor),

                agreePPToSButton.topAnchor.constraint(greaterThanOrEqualTo: ppTosContainer.topAnchor),
                agreePPToSButton.bottomAnchor.constraint(lessThanOrEqualTo: ppTosContainer.bottomAnchor),
                agreePPToSButton.centerYAnchor.constraint(equalTo: agreePPToSTextView.centerYAnchor),
                agreePPToSButton.leftAnchor.constraint(equalTo: agreePPToSTextView.rightAnchor, constant: 8),
                agreePPToSButton.rightAnchor.constraint(equalTo: ppTosContainer.rightAnchor),
            ]
        )
        
//        ppTos.addArrangedSubview(agreePPToSTextView)
//        ppTos.addArrangedSubview(agreePPToSButton)
        
        monthlySection.addArrangedSubview(monthlyPlanButton)
        monthlySection.addArrangedSubview(monthlyPrice)
        
        annualSection.addArrangedSubview(annualPlanButton)
        annualSection.addArrangedSubview(annualPrice)
        
        section1SV.addArrangedSubview(title)
        section1SV.addArrangedSubview(intro)
        section1SV.addArrangedSubview(monthlySection)
        monthlySection.isHidden = true
        annualSection.isHidden = true
        section1SV.addArrangedSubview(annualSection)
        // section1SV.addArrangedSubview(ppTos)

        section1SV.addArrangedSubview(ppTosContainer)
        section1SV.addArrangedSubview(disclaimer)
        
        return section1SV
    }
    
    @objc func agreePPToSFn(_ sender: UISwitch!) -> Void {
        if(sender.isOn){
            // TODO: persist agreement with ToS & PP
        } else {
            // TODO: persist disagreement with ToS & PP
            let alertController: UIAlertController = UIAlertController(
                title: "Disagreement",
                message: "Subscripto cannot be used if you do not agree to the Terms of Service and Privacy Policy; please either agree here or immediately discontinue use of the app.",
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: "Agree", style: .default, handler: { (action: UIAlertAction) -> Void in
                // TODO: persist agreement with ToS & PP
                self.agreePPToSButton.setOn(true, animated: true)
            }))
            self.present(alertController, animated: true, completion: nil)
        }
        agreePPToSButton.setOn(sender.isOn, animated: true)
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        pp.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.new, context: nil)
//        tos.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.new, context: nil)
//    }
//
//    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//        guard let textView = object as? UITextView else { return }
//
//        var leftCorrect: CGFloat = (textView.bounds.size.width - textView.contentSize.width * textView.zoomScale) / 2
//        leftCorrect = leftCorrect < 0.0 ? 0.0 : leftCorrect;
//        textView.contentInset.left = leftCorrect
//    }
    
    func stylePlanButton(_ button: UIButton) {
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
        button.layer.borderWidth = 0.8
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 10
        button.showsTouchWhenHighlighted = true
        button.layer.backgroundColor = UIColor.gray.cgColor
        button.titleLabel?.textColor = UIColor.white
        button.titleLabel?.adjustsFontForContentSizeCategory = false
        // button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title1)
        // button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 56)
        
        // button.titleLabel?.adjustsFontSizeToFitWidth = true
        // button.titleLabel?.minimumScaleFactor = 0.5
        // button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title1).withSize(UIFont.preferredFont(forTextStyle: .title1).pointSize * 4)
        button.layer.borderColor = UIColor.gray.cgColor
    }
    
    @objc func buttonsFn(sender: UIButton!) -> Void {
        guard agreePPToSButton.isOn else {
            let alertController = UIAlertController(title: "Agreement needed", message:
                "Purchase of a subscription plan is unable to proceed without agreement to the Terms of Service and Privacy Policy.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: .default,handler: nil))
            
            return self.present(alertController, animated: true, completion: nil)
        }
        
        // let us: UserSettings = UserSettings.getUserDefaultsSingleton()!
        switch(sender.tag){
        case 1:
            // monthly
            guard let product = self.products.first(where: { $0.productIdentifier == Products.Monthly }) else { return }
            Products.store.buyProduct(product)
        case 2:
            guard let product = self.products.first(where: { $0.productIdentifier == Products.Annual }) else { return }
            Products.store.buyProduct(product)
        default:
            break
        }
    }
    
    static func makeTextView(delegate: UITextViewDelegate? = nil) -> UITextView {
        let myTextView: UITextView = UITextView()
        myTextView.isScrollEnabled = false
        //        myTextView.isSelectable = false
        myTextView.isEditable = false
        myTextView.textContainer.lineFragmentPadding = 0;
        myTextView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        myTextView.delegate = delegate
        myTextView.backgroundColor = nil
        return myTextView
    }
    
    
    func makeAttributedText(hyperlinkedArea: String, fullString: String, url: String) -> NSAttributedString {
        let myAttributedText: NSMutableAttributedString = NSMutableAttributedString(string: fullString)
        myAttributedText.addAttributes([NSAttributedStringKey.link: url], range: (fullString as NSString).range(of: hyperlinkedArea))
        myAttributedText.addAttributes([NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .callout)], range: (fullString as NSString).range(of: fullString))
        myAttributedText.addAttributes([NSAttributedStringKey.foregroundColor: UIColor.gray.cgColor], range: (fullString as NSString).range(of: fullString))
        return myAttributedText
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("SubscriptionShop did appear")
        Products.store.registerVC(self) // Sets self as the provider of paymentStatusUI
        guard Products.productIdentifiers.count > 0 else {
            return self.callPKHUD(.label("Currently no products; please return to menu."), dimsBackground: false)
        }
        if(!appearingFromSafari){
            reload()
        }
        appearingFromSafari = false
    }
    
    var appearingFromSafari: Bool = false
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.hidePKHUD()
        Products.store.deregisterVC()
        print("SubscriptionShop will disappear")
        
//        pp.removeObserver(self, forKeyPath: "contentSize")
//        tos.removeObserver(self, forKeyPath: "contentSize")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("SubscriptionShop did disappear")
    }
    
    @objc func reload() {
        guard Products.productIdentifiers.count > 0 else { return print("No products to reload."); }
        self.callPKHUD(.labeledProgress(title: "Loading receipts...", subtitle: "Please wait."), dimsBackground: true)
        products = []
        
        let validationResult = ReceiptValidator().validateReceipt()
        switch validationResult {
        case .success(let parsedReceipt):
            print("requested receipt validation succeeded! Checking parsed receipt now.")
            /* If false, this method would typically prompt a popup telling the user that they have no subscription, so there's a special guard to not present it if they're already viewing the shop.
             * Once the user next backs out of the shop, validateReceipt() will be called in ViewController anyway. */
            let subscriptionActive: Bool = ViewController.checkParsedReceipt(parsedReceipt)
            if(subscriptionActive){
                // Apple review may have ended up here, having bought IAPs before entering app..?
                self.annualPlanButton.setAttributedTitle(
                    NSMutableAttributedString(string: "12-Month Plan unavailable\n(A subscription is already active)", attributes: [NSAttributedStringKey.font :UIFont.preferredFont(forTextStyle: .headline)]),
                    for: .normal
                )
                self.annualPlanButton.isEnabled = false
                self.annualSection.isHidden = false
                self.monthlyPlanButton.setAttributedTitle(
                    NSMutableAttributedString(string: "1-Month Plan unavailable\n(A subscription is already active)", attributes: [NSAttributedStringKey.font :UIFont.preferredFont(forTextStyle: .headline)]),
                    for: .normal
                )
                self.monthlyPlanButton.isEnabled = false
                self.monthlySection.isHidden = false
                self.hidePKHUD()
            } else {
                self.callPKHUD(.labeledProgress(title: "Loading products.", subtitle: "Please wait..."), dimsBackground: true)
                displayProducts()
            }
        case .error(let receiptValidationError):
            print("Unable to validate receipt. Error: " + receiptValidationError.localizedDescription)
            self.callPKHUD(.labeledProgress(title: "Loading products...", subtitle: "Please wait."), dimsBackground: true)
            displayProducts()
        }
    }
    
    static let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        
        formatter.formatterBehavior = .behavior10_4
        formatter.numberStyle = .currency
        
        return formatter
    }()
    
    func displayProducts(){
        Products.store.requestProducts{ products, error in
            if let unwrappedError: Error = error {
                self.callPKHUD(HUDContentType.labeledError(title: "Error requesting products", subtitle: unwrappedError.localizedDescription), dimsBackground: true)
            } else {
                self.products = products!

                /* Seems that no products are being listed during Apple review (but only sometimes..?) */
                for (_, product) in self.products.enumerated() {
                    SubscriptionShop.priceFormatter.locale = product.priceLocale
                    switch(product.productIdentifier){
                    case Products.Monthly:
                        self.monthlySection.isHidden = false
                        self.monthlyPlanButton.isEnabled = true
                        if(product.localizedTitle != ""){
                            self.monthlyPlanButton.setAttributedTitle(
                                NSMutableAttributedString(
                                    string: product.localizedTitle.replacingOccurrences(of: " (", with: "\n(").replacingOccurrences(of: "（", with: "\n（").replacingOccurrences(of: "trial", with: "FREE trial"),
                                    attributes: [NSAttributedStringKey.font : UIFont.preferredFont(forTextStyle: .headline)]
                                ),
                                for: .normal
                            )
                        }
                        self.monthlyPrice.text = "Renews for \(SubscriptionShop.priceFormatter.string(from: product.price) ?? "[ERROR]") every month"
                    case Products.Annual:
                        self.annualSection.isHidden = false
                        self.annualPlanButton.isEnabled = true
                        if(product.localizedTitle != ""){
                            self.annualPlanButton.setAttributedTitle(
                                NSMutableAttributedString(
                                    string: product.localizedTitle.replacingOccurrences(of: " (", with: "\n(").replacingOccurrences(of: "（", with: "\n（").replacingOccurrences(of: "trial", with: "FREE trial"),
                                    attributes: [NSAttributedStringKey.font : UIFont.preferredFont(forTextStyle: .headline)]
                                ),
                                for: .normal
                            )
                        }
                        self.annualPrice.text = "Renews for \(SubscriptionShop.priceFormatter.string(from: product.price) ?? "[ERROR]") every year"
                    default:
                        break
                    }
                }

                self.hidePKHUD()
            }
        }
    }
    
    @objc func restoreTapped(_ sender: AnyObject) {
        Products.store.restorePurchases()
    }
    
    /* Whenever a purchase notification is received from IAPHelper (indicating purchase/restore of a single product),
     * we overhear it via this notification observer (event listener) and reload the row corresponding to that product
     * in the tableView. This will presumably cause the cell — with the Buy/√ indicator button – to reload too. */
    @objc func handlePurchaseNotification(_ notification: Notification) {
        guard let productID = notification.object as? String else { return }
        
        for (_, product) in products.enumerated() {
            guard product.productIdentifier == productID else { continue }
            // product.subscriptionPeriod!.unit
            switch(productID){
            case Products.Annual:
                annualSection.isHidden = false
                self.annualPlanButton.setAttributedTitle(
                    NSMutableAttributedString(string: "12-Month Plan active!", attributes: [NSAttributedStringKey.font :UIFont.preferredFont(forTextStyle: .headline)]),
                    for: .normal
                )
                self.monthlyPlanButton.setAttributedTitle(
                    NSMutableAttributedString(string: "1-Month Plan unavailable\n(12-Month Plan active)", attributes: [NSAttributedStringKey.font :UIFont.preferredFont(forTextStyle: .headline)]),
                    for: .normal
                )
                self.monthlyPlanButton.isEnabled = false
                self.annualPlanButton.isEnabled = false
            case Products.Monthly:
                monthlySection.isHidden = false
                self.monthlyPlanButton.setAttributedTitle(
                    NSMutableAttributedString(string: "1-Month Plan active!", attributes: [NSAttributedStringKey.font :UIFont.preferredFont(forTextStyle: .headline)]),
                    for: .normal
                )
                self.annualPlanButton.setAttributedTitle(
                    NSMutableAttributedString(string: "12-Month Plan unavailable\n(1-Month Plan active)", attributes: [NSAttributedStringKey.font :UIFont.preferredFont(forTextStyle: .headline)]),
                    for: .normal
                )
                self.monthlyPlanButton.isEnabled = false
                self.annualPlanButton.isEnabled = false
            default:
                break
            }
        }
    }
}

extension SubscriptionShop: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        let safariVC: SFSafariViewController = SFSafariViewController(url: URL)
        appearingFromSafari = true
        present(safariVC, animated: true, completion: nil)
        return false
    }
}


extension SubscriptionShop: PaymentStatusUI {
    func callPKHUD(_ content: HUDContentType, dimsBackground: Bool) {
        print("Received call to callPKHUD()!")
        HUD.dimsBackground = dimsBackground
        HUD.allowsInteraction = false
        switch content {
        case .label(let title):
            HUD.show(.label(title))
        case .labeledError(let title, let subtitle):
            HUD.show(.labeledError(title: title, subtitle: subtitle))
        case .labeledProgress(let title, let subtitle):
            HUD.show(.labeledProgress(title: title, subtitle: subtitle))
        default:
            print("ERROR: unimplemented HUDContentType")
        }
    }
    
    func hidePKHUD(){
        print("Received call to hidePKHUD()!")
        HUD.hide()
    }
}
