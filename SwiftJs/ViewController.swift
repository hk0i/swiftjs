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

  @IBAction func nativeButton_touchUpInside(_ sender: UIButton) {
    let newText = self.textField!.text!
    self.webView!.evaluateJavaScript("webViewSetElementText('\(newText)')",
      completionHandler: {(result: Any?, error: Error?) -> Void in

      if error == nil {
        print("awesome it worked!")
      }
      else {
        if let error = error as? NSError {
          let userInfo = error.userInfo
          if let exceptionMessage = userInfo["WKJavaScriptExceptionMessage"] as? String {
            self.showMessage(exceptionMessage, title: "Javascript Error")
            print("Received an error from JS: \(exceptionMessage)")

            return; }
        }

        print("Received an error from JS: \(error)")

      }
    })
  }

  func showMessage(_ message: String, title: String?) {
    let actualTitle = title ?? ""
    let alert = UIAlertController(title: actualTitle, message: message, preferredStyle: .alert)
    let okButton = UIAlertAction(title: "OK", style: .default, handler: nil)
    alert.addAction(okButton)

    self.present(alert, animated: true, completion: nil)
  }

}

extension ViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage) {
      self.showMessage("name: \(message.name)\nmessage: \(message.body)", title: "A Message From JS!")
    }
}
