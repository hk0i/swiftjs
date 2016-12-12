//
//  ViewController.swift
//  SwiftJs
//
//  Created by Gregory McQuillan on 12/9/16.
//  Copyright © 2016 One Big Function. All rights reserved.
//

import UIKit
import WebKit

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
    config.userContentController.add(self, name: "callNative");
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
extension ViewController: WKScriptMessageHandler {

  func userContentController(_ userContentController: WKUserContentController,
      didReceive message: WKScriptMessage) {
    if let stringDict = message.body as? [String:String] {
      //if the message can be handled as a dictionary, assume `name`, `email`
      //and `phone` json
      self.handleNameEmailPhone(strings: stringDict)
    }
    else {
//      self.showMessage("name: \(message.name)\nmessage: \(message.body)", title: "A Message From JS!")
      self.debug("name: \(message.name)\nmessage: \(message.body)")
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
  func handleNameEmailPhone(strings: [String:String]) {
    let name = strings["name"] ?? "no name"
    let email = strings["email"] ?? "no email"
    let phone = strings["phone"] ?? "no phone"

    self.debug("name, email, phone received!\n"
      + "\(name)'s email is \(email)\n"
      + "\(name)'s phone is \(phone)\n"
    )
  }
}
