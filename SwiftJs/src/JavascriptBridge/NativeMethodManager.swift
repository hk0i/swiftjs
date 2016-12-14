import WebKit

/**
 * Native method handler which is eventually called from javascript, takes a single `Any` parameter.
 * `Any` could be one of:
 *
 * - `NSNumber`
 * - `NSString`
 * - `NSDate`
 * - `NSArray`
 * - `NSDictionary`
 * - `NSNull`
 *
 * **see**: [WKScriptMessage.body](https://developer.apple.com/reference/webkit/wkscriptmessage/1417901-body)
 */
typealias NativeMethodHandler = (Any) -> Void

/**
 * Wraps handling of native method calls from javascript.
 *
 * ## Notes:
 * Inherits from `NSObject` because instances of the object *must* conform to the
 * `NSObjectProtocol` to be used with the `WKScriptMessageHandler` protocol.
 */
class NativeMethodManager: NSObject {
  let controller: WKUserContentController

  /**
   * Acts as an access control to disallow any class methods that have
   * not been added explicitly and lets us know what methods
   * have been registered to the method manager.
   */
  var nativeMethods: [String:NativeMethodHandler] = [:]

  init(configuration: WKWebViewConfiguration) {
    self.controller = configuration.userContentController
  }

  /**
   * Creates a new method with `name` and exposes it to the javascript
   * via `window.webkit.messageHandlers.name`.
   *
   * Example:
   *
   * In swift,
   *
   *   ```swift
   *   let config = WKWebViewConfiguration()
   *   let methodManager = NativeMethodManager(configuration: config)
   *   //self.webView declared elsewhere as an outlet to a WKWebView.
   *   self.webView = WKWebView(frame: webFrame, configuration: config)
   *   methodManager.addMethod(name: "quack", method: { (param) in
   *     if let name = param as? String {
   *       print("I said quack, \(param)")
   *     }
   *   })
   *   ```
   *
   *   ```javascript
   *   window.webkit.messageHandlers.quack.postMessage('John');
   *   ```
   * In the native console window, the following is output:
   *
   *   ```
   *   I said quack, John
   *   ```
   */
  func addMethod(name: String, method: @escaping NativeMethodHandler) {
    if !name.isEmpty {
      if self.nativeMethods.keys.contains(name) {
        print("addMethod: WARNING - overriding existing method `\(name)`")
      }

      self.controller.add(self, name: name)
      self.nativeMethods[name] = method
    }
    else {
      assertionFailure("addMethod: `name` cannot be empty")
    }
  }
}

/**
 * Adds support for script handling on the native side
 */
extension NativeMethodManager: WKScriptMessageHandler {

  func userContentController(_ userContentController: WKUserContentController,
      didReceive message: WKScriptMessage) {
    if self.nativeMethods.keys.contains(message.name) {
      self.nativeMethods[message.name]!(message.body)
    }
    else {
      print("Could not find native method `\(message.name)`")
    }
  }
}
