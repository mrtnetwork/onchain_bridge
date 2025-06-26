import Cocoa
import FlutterMacOS
@preconcurrency import WebKit


class NativeViewFactory: NSObject, FlutterPlatformViewFactory,WKNavigationDelegate,@preconcurrency WKUIDelegate {
    private var webView: WKWebView!
    public let id:String
    private var channel: FlutterMethodChannel
    private var webConfiguration:WKWebViewConfiguration
    //    private var view: WebViewWrapper!
    private var viewWidth: CGFloat = 0
    private var viewHeight: CGFloat = 0
    
    	
    
    
    init(channel: FlutterMethodChannel,id:String,url:String?,jsInterface: String?) {
        self.channel = channel
        self.id = id
        self.webConfiguration = WKWebViewConfiguration()
        super.init()
        
        webView = WKWebView(frame: .zero,configuration:self.webConfiguration)
        webView.uiDelegate = self
        self.webConfiguration.preferences = WKPreferences()
        self.webConfiguration.preferences.javaScriptEnabled = true
        self.webConfiguration.preferences.javaScriptCanOpenWindowsAutomatically = true
        self.webConfiguration.websiteDataStore = .default()
        //        self.webConfiguration.setValue(true, forKey: "developerExtrasEnabled")
        
        webView.navigationDelegate = self
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        
        if let jsInterface = jsInterface {
            self.addJsInterface(name: jsInterface)
        }
        
        if let url = url {
            self.openPage(url: url)
        }
        
    }
    
    
    
    
    func create(
        withViewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> NSView {
        let view = NSView(frame: .zero)
        webView.autoresizingMask = [.width, .height]
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(self.webView)
        webView.leadingAnchor.constraint(equalTo:view.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        return view
    }
    
    public func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol)? {
        return FlutterStandardMessageCodec.sharedInstance()
    }
    
    var hasLoadedInitialURL = false
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let data = WebViewData.toJson(
            id: self.id,
            eventName: WebViewConst.onPageFinished,
            view: webView,
            url: webView.url?.absoluteString
        )
        self.channel.invokeMethod(WebViewConst.webView, arguments: data.toJson())
        
    }
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        hasLoadedInitialURL = false
    }
    
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let errorMessage = (error as NSError).localizedDescription
        let isInitialLoad = !hasLoadedInitialURL

            if isInitialLoad {
                let html = """
                <html>
                <head><meta name='viewport' content='width=device-width, initial-scale=1.0'></head>
                <body style='font-family: -apple-system; text-align: center; padding: 20px;'>
                    <h2>Page Load Failed</h2>
                    <p>\(errorMessage)</p>
                </body>
                </html>
                """

                webView.loadHTMLString(html, baseURL: nil)
            }
        let data = WebViewData.toJson(id: self.id, eventName: WebViewConst.onPageError, view: webView, message: errorMessage,
                                      url: webView.url?.absoluteString)
        self.channel.invokeMethod(WebViewConst.webView, arguments: data.toJson())
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        hasLoadedInitialURL = true
        webView.evaluateJavaScript(WebViewConst.faviIconScript) { result, error in
            if let result = result as? String {
                let data = WebViewData.toJson(id: self.id, eventName: WebViewConst.onPageStart, view: webView, url: webView.url?.absoluteString, favicon: result)
                self.channel.invokeMethod(WebViewConst.webView, arguments: data.toJson())
            } else {
                let data = WebViewData.toJson(id: self.id, eventName: WebViewConst.onPageStart, view: webView, url: webView.url?.absoluteString)
                self.channel.invokeMethod(WebViewConst.webView, arguments: data.toJson())
                
            }
        }
       
    }
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
           let alert = NSAlert()
           alert.messageText = message
           alert.addButton(withTitle: "OK")
           alert.runModal()
           completionHandler()
       }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        let result = alert.runModal() == .alertFirstButtonReturn
        completionHandler(result)
    }
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alert = NSAlert()
        alert.messageText = prompt
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")

        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        input.stringValue = defaultText ?? ""
        alert.accessoryView = input

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            completionHandler(input.stringValue)
        } else {
            completionHandler(nil)
        }
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            let progress = webView.estimatedProgress
            let progressPercentage = Int(progress * 100)
            let data = WebViewData.toJson(id: self.id, eventName: WebViewConst.onPageProgress, view: webView, progress: progressPercentage)
            self.channel.invokeMethod(WebViewConst.webView, arguments: data.toJson())
        }
    }
 
    func dispose(){
        webView.reload()
        webView.stopLoading()
        webView.removeFromSuperview()
        
    }
    func openPage(url: String) {
        if let url = URL(string: url) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    func updateFrameSize(width:CGFloat,height:CGFloat) {
        self.viewWidth = width
        self.viewHeight = height
        
    }
    private func convertToString(_ result: Any?) -> String? {
        guard let result = result else { return nil }
        
        if let booleanResult = result as? Bool {
            return booleanResult ? "true" : "false"
        } else if let stringResult = result as? String {
            return stringResult
        } else if let numberResult = result as? NSNumber {
            return numberResult.stringValue
        } else {
            return "Unexpected result type: \(String(describing: result))"
        }
    }
    // Inject JavaScript code
    func injectJavaScript(jsCode: String, completion: @escaping (String?) -> Void, error: @escaping (String) -> Void) {
        webView.evaluateJavaScript(jsCode) { result, jsError in
            if let jsError = jsError {
                error(jsError.localizedDescription)
            } else {
                // Convert the result to a string
                let resultString = self.convertToString(result)
                completion(resultString)
            }
        }
    }
    // Check if can go forward
    func canGoForward() -> Bool {
        return webView.canGoForward
    }
    // Check if can go back
    func canGoBack() -> Bool {
        return webView.canGoBack
    }
    func goBack() {
        webView.goBack()
    }
    
    // Go forward
    func goForward() {
        webView.goForward()
    }
    func getScript() -> WKUserScript {
        let consoleScriptStr = """
            window.onChain = {
                scriptId: '\(self.id)'
            };
            (function() {
        window.addEventListener("error", function (e) {
                                   window.webkit.messageHandlers.onChain.postMessage({
                                       type: 'log',
                                       data: "Error occurred: " + e.error.message + e + e.error,
                                       id: '1',
                                       requestId: '0',
                                   });
           return false;
        })
            window.addEventListener('unhandledrejection', function (e) {
                        // Send the message to the native side
                        window.webkit.messageHandlers.onChain.postMessage({
                            type: 'log',
                            data: "Error occurred: " + e.reason.message + e + e.reason, 
                            id: '1',
                            requestId: '0',
                        });
            })
            // Capture uncaught errors
            window.onerror = function(message, source, lineno, colno, error) {
          
                // Send the message to the native side
                window.webkit.messageHandlers.onChain.postMessage({
                    type: 'log',
                    data: "Error occurred: " + message + source + lineno + colno,
                    id: '1',
                    requestId: '0',
                });
        
                // Return true to prevent the error from being logged in the console (optional)
                return true;
            };
                var originalLog = console.log;
                console.log = function(message) {
                    originalLog.apply(console, arguments);
                    window.webkit.messageHandlers.onChain.postMessage({type: 'log', data: JSON.stringify(message),id:'1',requestId:'0'});
                };
                
                var originalError = console.error;
                console.error = function(message) {
                    originalError.apply(console, arguments);
                    window.webkit.messageHandlers.onChain.postMessage({type: 'log', data: JSON.stringify(message),id:'1',requestId:'0'});
                };
        
                var originalWarn = console.warn;
                console.warn = function(message) {
                    originalWarn.apply(console, arguments);
                    window.webkit.messageHandlers.onChain.postMessage({type: 'log', data: JSON.stringify(message),id:'1',requestId:'0'});
                };
            })();
        """
        let script = WKUserScript(
            source: consoleScriptStr,
            injectionTime: .atDocumentStart, // Inject at the start of the document
            forMainFrameOnly: false
        )
        return script
    }
    // Reload the page
    func reload() {
        webView.reload()
    }
    func addJsInterface(name:String){
        let userContentController = webConfiguration.userContentController
        let scriptHandler = ScriptMessageHandler(viewType: self.id, channel: self.channel,webview:self.webView)
        userContentController.addUserScript(getScript())
        userContentController.add(scriptHandler, name: name)
        
        
        
    }
    func removeJsInterface(name:String) {
        let userContentController = webConfiguration.userContentController
        userContentController.removeScriptMessageHandler(forName: name)
        
        
    }
    
}
