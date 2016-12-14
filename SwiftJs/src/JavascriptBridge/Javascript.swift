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

  init() {
    assertionFailure("Fully static class, no instantiation needed.")
  }

  /**
   * Executes arbitrary javascript code snippet specified by `code`
   * in the given `webview`.
   *
   * - parameter code: javascript code to execute
   * - parameter webview: webview to run the javascript on
   */
  public static func exec(_ code: String, onWebView webview: WKWebView, completion: JavascriptCompletionHandler?) {
    print("Executing js:\n    \(code)")

    webview.evaluateJavaScript(code, completionHandler: { (result: Any?, error: Error?) in
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
