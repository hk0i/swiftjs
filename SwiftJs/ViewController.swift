//
//  ViewController.swift
//  SwiftJs
//
//  Created by Gregory McQuillan on 12/9/16.
//  Copyright © 2016 One Big Function. All rights reserved.
//

import UIKit
import WebKit


//TODO: convert all print() statements to use a wrapper class for debug output
//that will get stripped in release builds.

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

class ViewController: UIViewController {

  @IBOutlet weak var container: UIView!
  @IBOutlet weak var textField: UITextField!
  @IBOutlet weak var logTextView: UITextView!

  var webView: WKWebView?

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.

    var webFrame = self.container!.frame
    webFrame.origin.x = 0
    webFrame.origin.y = 0

    let config = WKWebViewConfiguration()
    let methodManager = NativeMethodManager(configuration: config)
    methodManager.addMethod(name: "callNative", method: { (message) in
      print("Received `callNative` with message: '\(message)'")
      NativeCallHandler.handle(message: message);
    })
//    config.userContentController.add(self, name: "callNative");
    self.webView = WKWebView(frame: webFrame, configuration: config)
    self.container!.addSubview(webView!)

    let testUrl: URL! = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "html")
    self.webView!.loadFileURL(testUrl, allowingReadAccessTo: testUrl)

  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  func debug(_ message: String) {
    logTextView.text = message
  }

  /**
   * Attempts to create a JSON object from a string if it contains a comma.
   * If a `,` is found in the string, we will split the values. If we have
   * exactly 3 values, we create a new JSON string using the values as
   * `name`, `phone`, and `email` in that order.
   *
   * - parameter string: a `String` that may or may not contain data to be
   *                     reconstructed as a JSON object.
   *
   * - returns: Returns a new JSON `String` if possible, or the original
   *            input string if not.
   */
  func jsonFromString(_ string: String) -> String {
    if string.contains(",") {
      //try to parse out multiple comma separated values and see if we can pass
      //those instead.
      let array = string.components(separatedBy: [","])
      if array.count == 3 {
        //if we have exactly 3 values in our array, treat it as a name, phone,
        //email list.
        return "{\"name\": \"\(array[0])\", \"phone\": \"\(array[1])\", \"email\": \"\(array[2])\"}"
      }
    }

    return string;
  }

  @IBAction func nativeButton_touchUpInside(_ sender: UIButton) {
    let newText = self.jsonFromString(self.textField!.text!)
    self.webView!.evaluateJavaScript("handleNativeCall('\(newText)')",
      completionHandler: {(result: Any?, error: Error?) -> Void in

      if error == nil {
        self.debug("awesome it worked!")
      }
      else {
        if let error = error as? NSError {
          let userInfo = error.userInfo
          if let exceptionMessage = userInfo["WKJavaScriptExceptionMessage"] as? String {
            self.showMessage(exceptionMessage, title: "Javascript Error")
            self.debug("Received an error from JS: \(exceptionMessage)")

            return; }
        }

        self.debug("Received an error from JS: \(error)")

      }
    })
  }

  /**
   * Shows an alert message
   *
   * - parameter message: the message body to display in the alert view
   * - parameter title: the title text to display above the `message` in the
   *                    alert view.
   */
  func showMessage(_ message: String, title: String?) {
    let actualTitle = title ?? ""
    let alert = UIAlertController(title: actualTitle, message: message, preferredStyle: .alert)
    let okButton = UIAlertAction(title: "OK", style: .default, handler: nil)
    alert.addAction(okButton)

    self.present(alert, animated: true, completion: nil)
  }

}

/**
 * Adds support for javascript message handling on the native side
 */
class NativeCallHandler {

  static func handle(message: Any) {
    if let stringDict = message as? [String:String] {
      //if the message can be handled as a dictionary, assume `name`, `email`
      //and `phone` json
      self.handleNameEmailPhone(strings: stringDict)
    }
    else {
//      self.showMessage("name: \(message.name)\nmessage: \(message.body)", title: "A Message From JS!")
      print("message: \(message)")
    }
  }

  /**
   * Handles a JSON message from JS which presumably contains the following
   * fields:
   *
   * - `email: String`
   * - `name: String`
   * - `phone: String`
   */
  static func handleNameEmailPhone(strings: [String:String]) {
    let name = strings["name"] ?? "no name"
    let email = strings["email"] ?? "no email"
    let phone = strings["phone"] ?? "no phone"

    print("name, email, phone received!\n"
      + "\(name)'s email is \(email)\n"
      + "\(name)'s phone is \(phone)\n"
    )
  }
}
