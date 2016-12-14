# SwiftJS

A simple example of how to do communication from javascript in a `WKWebView`
to iOS native and vice versa using Swift 3 without pulling in a full framework
like Cordova.

## To JS

To make calls from native *to javascript*, create a `Javascript` instance
with your `WKWebView`:

```swift
class ViewController: UIViewController {
    var webView: WKWebView?
    var javascript: Javascript?

    // ...

    override func viewDidLoad() {
        self.webView = WKWebView(frame: webFrame, configuration: config)
        self.javascript = Javascript(webView: self.webView!)
    }
}
```

Then wherever you want to run JS from the UI:

```swift
// inside some function
self.javascript!.exec("WebView.handleCallFromNative(\(newText))", completion: { (result: JavascriptResult) in
  //example of how to check for an error message
  if let errorMessage = result.errorMessage {
    print(errorMessage)
  }
  else if let retVal = result.returnValue {
    print("Javascript Returned Value: '\(retVal)'")
  }

  print("result: \(result)")
})
```

## To Native

To make calls from your javascript to native some additional set up is required.

1. Create a new `NativeMethodManager()` and pass it a `WKWebViewConfiguration()`
   to work with:

   ```swift
   let config = WKWebViewConfiguration()
   let methodManager = NativeMethodManager(configuration: config)
   ```

2. Then, add the methods you want to it using `addMethod()`:

   ```swift
   methodManager.addMethod(name: "callNative", method: { (message) in
     //message is Any? type, so it must be cast.
     if let name = message as? String {
       print ("Quack, \(name)")
     }
     print("Received `callNative` with message: '\(message)'")
   })
   ```

3. Now your method will be available from the javascript under the
   `window.webkit.messageHandlers` object and can be invoked by calling
   `postMessage()` on your object:

   ```javascript
   window.webkit.messageHandlers.callNative.postMessage(message);
   ```

   In this example `callNative` is the name of the method we set up in the
   `addMethod(name:method:)` call from step 2. If we had named the method
   `squish` in step 2, we could have to call
   `window.webkit.messageHandlers.squish.postMessage(message);`
