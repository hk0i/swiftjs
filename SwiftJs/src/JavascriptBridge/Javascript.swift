import WebKit

typealias JavascriptCompletionHandler = (JavascriptResult) -> Void

/**
 * Encapsulates the result from attempting to execute a javascript snippet inside
 * a `WKWebView`.
 */
class JavascriptResult {
  let returnValue: Any?
  let error: Error?
  let errorMessage: String?
  let isSuccess: Bool

  init(returnValue: Any?, error: Error?, isSuccess: Bool) {
    self.returnValue = returnValue
    self.error = error
    self.isSuccess = isSuccess

    self.errorMessage = (error as? NSError)?
      .userInfo["WKJavaScriptExceptionMessage"] as? String ?? nil
  }
} // JavascriptResult

/**
 * Adds the description property to `JavascriptResult` for debug printing
 */
extension JavascriptResult: CustomStringConvertible {
  var description: String {
    return "\(String(describing: JavascriptResult.self)) {\n"
      + "\treturnValue: \(self.returnValue),\n"
      + "\tisSuccess: \(self.isSuccess),\n"
      + "\terrorMessage: \(self.errorMessage),\n"
      + "\terror: \(self.error),\n"
      + "}"
  }
} //JavascriptResult: CustomStringConvertible

/**
 * Abstracts executing javascript inside webviews.
 */
class Javascript {

  let webView: WKWebView

  init(webView: WKWebView) {
    self.webView = webView
  }

  /**
   * Executes arbitrary javascript code snippet specified by `code`
   * in the given `webview`.
   *
   * - parameter code: javascript code to execute
   * - parameter completion: the `JavascriptCompletionHandler` to execute after
   *                         returning from the js execution.
   */
  public func exec(_ code: String, completion: JavascriptCompletionHandler?) {
    print("Executing js:\n    \(code)")

    self.webView.evaluateJavaScript(code, completionHandler: { (result: Any?, error: Error?) in
      if error == nil {
        print("Js execution successful")
        completion?(JavascriptResult(returnValue: result, error: nil, isSuccess: true))
      }
      else {
        print("Received an error from JS: \(error)")
        completion?(JavascriptResult(returnValue: result, error: error, isSuccess: false))
      }

    })
  }
} // JavascriptResult
