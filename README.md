# Subscripto

An app that handles subscriptions and local receipt validation! Used by [LinguaBrowse](https://itunes.apple.com/us/app/linguabrowse/id1281350165?ls=1&mt=8) (see below).

## Preview

### Working flow

The Subscripto flow, as featured in [LinguaBrowse](https://itunes.apple.com/us/app/linguabrowse/id1281350165?ls=1&mt=8) and demonstrated on my iPhone, using an iTunes Connect Sandbox tester:

<div style="display: flex; width: 100%;">
    <img src="/readme_img/0.PNG" width="200px"</img>
    <img src="/readme_img/1.PNG" width="200px"</img>
    <img src="/readme_img/2.PNG" width="200px"</img>
    <img src="/readme_img/3.PNG" width="200px"</img>
    <img src="/readme_img/4.PNG" width="200px"</img>
    <img src="/readme_img/5.PNG" width="200px"</img>
    <img src="/readme_img/6.PNG" width="200px"</img>
    <img src="/readme_img/7.PNG" width="200px"</img>
</div>

Note that you will need to replace my placeholder product identifiers in `Products.swift` to match ones registered on your iTunes Connect account in order to replicate this!

<!-- ### App Review flow -->

<!-- In the most recent App Review for [LinguaBrowse](https://itunes.apple.com/us/app/linguabrowse/id1281350165?ls=1&mt=8), the reviewer gave up at the "Processing transactions..." prompt on one review (first screenshot), and then found that no products were appearing at all on the second review (second screenshot; has also happened in previous reviews). Unfortunately, that's all the information I have. -->

<!-- As far as I can tell, they just needed more patience for the first failure (it's their own backend causing the delay, after all), but I'm baffled by the second failure; those products *should* be appearing, as they do on my phone. It could only be explained by iTunes Connect failing to pass a populated list of products with their appropriate names into the `productsRequestCompletionHandler?(products, nil)` handler in `IAPHelper.swift`'s `extension IAPHelper: SKProductsRequestDelegate`. -->

<!-- <div style="display: flex; width: 100%;">
    <img src="/readme_img/review1.PNG" width="400px"</img>
    <img src="/readme_img/review0.PNG" width="246px"</img>
</div> -->

<!-- **Alternative thought:** is there some issue with local receipt validation that I need to cater for in Apple's testing environment? -->

### Gotchas

If ever your submitted build is rejected, **always** go back to your In-App Purchase metadata section. Apple may reject *all* of your subscription IAPs after each build rejection, and this fact won't be visible merely from the Resolution Center. Each time you submit, ensure that none of your subscription-related IAPs are in an error state (e.g. "pending developer action" or "metadata incomplete").

## Prior art

I should note that the code for subscriptions and the in-app storefront is based on Ray Wenderlich's [ARS](https://www.raywenderlich.com/659-in-app-purchases-auto-renewable-subscriptions-tutorial) and [IAP](https://www.raywenderlich.com/5456-in-app-purchase-tutorial-getting-started) guides. However, I have adapted the ARS guide to use local receipt validation, by the grace of Andrew C Bancroft's [SwiftyLocalReceiptValidator](https://github.com/andrewcbancroft/SwiftyLocalReceiptValidator).


## Features

### Robust receipt check

Upon opening the app or returning to the main view, the local receipt is checked.

* If the receipt is found and valid, then we run `ViewController.onAccessPermitted()`, setting up the UI and effectively unlocking the app. We do not persist this permission; local receipt-checking is quick, so the receipt itself is our persistence store!

* If the receipt is not found, we allow the user to refresh the receipt. If still not found, they may continue to refresh the receipt fruitlessly, or go to the store (`SubscriptionShop.swift`).

* If the receipt is found, but no active subscription identified within it, then we prompt the user to go to our store (`SubscriptionShop.swift`). 

### Minimalist Subscription Shop

The storefront UI is constructed completely programmatically. When `viewDidAppear()` is called, the `reload()` method is invoked. At this point, the buttons for the products are not yet visible (Apple rejected my build that used placeholders). The first thing to happen is a receipt check. This is to guard against users being told to make purchases if they already have an active subscription.

* If the receipt check finds an active subscription, we reveal (but disable) the buttons for the products and clarify that a subscription is already active.
* Otherwise, we call `Products.store.requestProducts()` to request our products from iTunes Connect. If it succeeds bearing products, we reveal them, showing localised descriptions and prices. If it fails, we show an error message to the user. If it succeeds, yet bears no products, then no buttons appear at all (you will encounter this yourself unless you register some products on your iTunes Connect account and set `Products.Annual` and `Products.Monthly` to match). This seems to be the failure symptom I'm getting during App Review.

On the happy path, a user would click a product, provide login details for their iTunes Connect account, and `handlePurchaseNotification()` would be called. As a result, the buttons would deactivate, and descriptive text would clarify that a subscription is now active. The user would then (hopefully) choose to leave the shop. This would take them back to `ViewController`, which would check their local receipt, find that it now bears an active subscription, and unlock the app.

There's also some Privacy Policy and Terms of Service handling in there, but I've disabled half of it to keep the focus on subscription management. Ideally, you should check that your user agrees with the PP & ToS before permitting them to use the app. 

### Robust to exploits

I've fixed a couple of weaknesses of Ray Wenderlich's ARS implementation in the process:

1. This app schedules a re-check of when the subscription has expired, so that users can't just start a free trial subscription, cancel it, then leave the app open indefinitely to get a never-ending free subscription. This re-check isn't perfect, but it's better than nothing.
2. "Restore purchases" cross-checks the newly-refreshed receipt so as not to restore an expired subscription (yes, expired subscriptions **do** pass through `SKPaymentTransactionObserver`'s `paymentQueue(_:updatedTransactions:)` callback). Before this fix, users could start and cancel a free trial subscription, then just restore the subscription each time to retain access to the product indefinitely for free.

## Notes if you want to base a project on this

1. Replace my placeholder product identifiers in `Products.swift` to match ones registered on your iTunes Connect account.
2. Don't use my (HTTP Status 404) Privacy Policy and Terms of Service; provide your own custom ones.
3. Do ensure that the user agreed to the Privacy Policy and Terms of Service upon returning to `ViewController`. Nothing's stopping them from refusing to press that button in `SubscriptionStore`.
4. I provide no guarantee/warranty that this will work as intended, nor that I will maintain it in any way. 
5. Do provide your own `libcrypto.a` and `libssl.a` from a trusted source, rather than using my provided ones from [krzyzanowskim](https://github.com/krzyzanowskim/OpenSSL) – ideally build it yourself from source. 
6. Obfuscate any function names like "permitAccess" or "checkValidity" to make the code harder to reverse-engineer and hack (Apple recommend this themselves).
7. Feel free to tell me how it goes and send Pull Requests to improve this project!

## More of my stuff

This app represents the subscriptions flow for my main app, LinguaBrowse – a browser for the foreign-language web, providing text transliteration (for languages like Chinese and Japanese) and tap-to-define functionality (to avoid having to switch out to a dedicated dictionary app).

<div style="display: flex;">
    <img src="/readme_img/LinguaBrowse.PNG" width="64px"</img>
    <img src="/readme_img/TheBox.PNG" width="64px"</img>
</div>

* [LinguaBrowse](https://itunes.apple.com/us/app/linguabrowse/id1281350165?ls=1&mt=8) (iOS) on the App Store – made in Swift
* [LinguaBrowse](https://itunes.apple.com/gb/app/linguabrowse/id1422884180?mt=12) (macOS) on the App Store – made in React Native + TypeScript + Swift
* [Plucky Box](https://itunes.apple.com/us/app/plucky-box/id1375337845?ls=1&mt=8) (iOS) on the App Store, [GitHub](https://github.com/shirakaba/react-native-typescript-2d-game), [expo.io](https://expo.io/@bottledlogic/the-box) as Android/iOS – made in React Native + TypeScript
* [@LinguaBrowse](https://twitter.com/LinguaBrowse) – my Twitter account. I talk about NativeScript, React Native, TypeScript, Chinese, Japanese, and my apps on there.
